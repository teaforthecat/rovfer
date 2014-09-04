require 'nokogiri'

module Rovfer
  module Builder
    def new_node name, content=nil, attrs={}
      node = Nokogiri::XML::Node.new(name, @xml )
      attrs.collect{ | k,v| node[k] = v}
      node.content = content if content
      node << yield if block_given?
      node
    end
  end

  class Parser
    include Builder

    attr_accessor :xml_path
    attr_accessor :xml
    attr_accessor :namespace

    NameSpaces = {'vmw' => "http://www.vmware.com/schema/ovf"}

    # default to vmware for now
    def initialize(xml_path, namespace='vmw')
      @xml_path = xml_path
      load
      @xml.root.add_namespace namespace, NameSpaces[namespace]
      @namespace = namespace
    end

    def save
      open(@xml_path, 'w+') do |f|
        f.puts @xml.to_xml(indent: 2)
      end
    end

    def reload
      load
    end

    def load
      @xml = Nokogiri::XML::Document.parse(open(@xml_path))
    end

    def references
      find('References','File').collect do |e|
        e.attributes["href"].value
      end
    end

    def disks
      find('DiskSection','Disk').collect do |e|
        e.attributes
      end
    end

    def disk_image_parent_id
      disk_image.xpath('.//rasd:Parent').first.content
    end

    def disk_image
      find_item 'Disk Image'
    end

    def disk_image_config
      @disk_image_config ||= DiskImageConfig.new(@xml, disk_image)
    end

    def networks
      find('NetworkSection', 'Network').collect do |e|
        e.attributes['name'].value
      end
    end

    def networks= vlans
      section = find('NetworkSection').first
      section.xpath('.//xmlns:Network').remove
      vlans.each do |vlan|
        section << new_node( 'Network', nil, 'ovf:name' => vlan) do
          new_node 'Description', vlan
        end
      end
      subtype = 'VmxNet3' #vmware
      self.nics = Hash[vlans.zip([subtype]*vlans.size)]
      section
    end

    def nics
      items = find_items.select{ |e| e.xpath('.//rasd:Connection').size == 1 } #best guess
      items.collect{ |e| e.xpath('.//rasd:Connection').first.content }
    end

    # @param attrs[Hash]
    # @example nics = {'DC_DMZ_CLIENT_QC_AS' => 'VmxNet3'}
    def nics= attrs
      items = find_items.select{ |e| e.xpath('.//rasd:Connection').size == 1 } #best guess
      attributes = attrs.to_a
      raise MissingElement.new('Network Adapter (may be missing or short one)') if items.size != attrs.size
      items.each_with_index do |item,i|
        vlan,subtype = attributes[i]
        item.xpath('.//rasd:Connection').first.content = vlan
        item.xpath('.//rasd:ResourceSubType').first.content = subtype
        item.xpath('.//rasd:ElementName').first.content = "Network Adapter #{i+1}"
        # item.xpath('.//rasd:Description').first.content = "#{subtype} ethernet adapter on \"#{vlan}\""
      end
    end

    def os_type
      section = find('VirtualSystem', 'OperatingSystemSection').first
      # section.xpath('.//vbox:OSType').text #vbox
      attr = section.attribute_with_ns('osType', ns)
      attr && attr.value
    end

    def set_os_type name, version, desc
      section = find('VirtualSystem', 'OperatingSystemSection').first
      section["#{namespace}:osType"] = name #vmw
      # section << new_node( 'vbox:OSType', name ) #virtualbox
      section["ovf:version"] = version
      section.xpath('.//xmlns:Description').first.content = desc if desc
    end

    # aka: hardware version
    def system_type
      section = find('VirtualSystem', 'VirtualHardwareSection', 'System')
      section.xpath('.//vssd:VirtualSystemType').first.content
    end

    def system_type= str
      section = find('VirtualSystem', 'VirtualHardwareSection', 'System')
      section.xpath('.//vssd:VirtualSystemType').first.content = str
    end

    def ram
      find_item('Memory Size').xpath('.//rasd:VirtualQuantity').first.content
    end

    def ram= megabytes
      item = find_item 'Memory Size'
      item.xpath('.//rasd:AllocationUnits').first.content = 'MegaBytes'
      item.xpath('.//rasd:Caption').first.content = "#{megabytes} MB of memory"
      item.xpath('.//rasd:ElementName').first.content = "#{megabytes} MB of memory"
      item.xpath('.//rasd:VirtualQuantity').first.content = megabytes
    end

    def scsi_controller_type
      item = scsi_controller_item
      item.xpath('.//rasd:ResourceSubType').first.content
    end

    def scsi_controller_type= type
      remove_ide_controllers
      begin
        item = scsi_controller_item
        subtype_item = item.xpath('.//rasd:ResourceSubType').first
      rescue MissingElement
        item = build_scsi_controller_item
        subtype_item = item.children.find{ |e| e.name == 'rasd:ResourceSubType'}
      end
      subtype_item.content = type
      find_items.first.parent << item
    end

    # only one disk supported
    def scsi_controller_item
      find_item('SCSI Controller')
    end

    def build_scsi_controller_item
      item = new_node 'Item'
      { "rasd:Address"         => 0,
       "rasd:Caption"         => "SCSIController0",
       "rasd:Description"     => "SCSI Controller",
       "rasd:ElementName"     => "SCSIController0",
       # this could be a problem, probably has to match as disk's 'rasd:Parent' - just guessing
       "rasd:InstanceID"      => disk_image_parent_id,
       "rasd:ResourceSubType" => "VirtualSCSI",
       "rasd:ResourceType"    => '6'}.each do |k,v|
        item << new_node( k, v )
      end
      item
    end

    def remove_ide_controllers
      begin
        while (item = find_item('IDE Controller'))
          item.remove
        end
      rescue MissingElement
      end
    end

    def add_special_vmware_config
      section = find( 'VirtualSystem', 'VirtualHardwareSection' ).first
      SpecialVmWareConfig.attrs.each do |k,v|
        section << new_node( 'vmw:Config', nil, 'vmw:key' => k, 'vmw:value' => v)
      end
    end

    # description seems to be the best way to identify an item
    def find_item description
      items = find_items
      elem = items.xpath(".//rasd:Description").find{ |e| e.content == description }
      raise MissingElement.new(description) if elem.nil?
      elem.parent
    end

    def find_items
      find('VirtualSystem', 'VirtualHardwareSection','Item')
    end

    def find(*elements)
      @xml.xpath(get_in_envelope(*elements))
    end

    def ns
      xml.namespaces["xmlns:#{namespace}"]
    end

    def get_in_envelope *elements
      ['/xmlns:Envelope', elements.collect{ |e| "xmlns:#{e}" }].join('/')
    end

    class MissingElement < Exception; end
  end


  class SpecialVmWareConfig
    @@attrs = {"cpuHotAddEnabled"          => "true",
               "cpuHotRemoveEnabled"       => "true",
               "firmware"                  => "bios",
               "virtualICH7MPresent"       => "false",
               "virtualSMCPresent"         => "false",
               "memoryHotAddEnabled"       => "true",
               "nestedHVEnabled"           => "false",
               "powerOpInfo.powerOffType"  => "soft",
               "powerOpInfo.resetType"     => "soft",
               "powerOpInfo.standbyAction" => "checkpoint",
               "powerOpInfo.suspendType"   => "hard",
               "tools.afterPowerOn"        => "true",
               "tools.afterResume"         => "true",
               "tools.beforeGuestShutdown" => "true",
               "tools.beforeGuestStandby"  => "true",
               "tools.syncTimeWithHost"    => "false",
               "tools.toolsUpgradePolicy"  => "manual",
              }
    def self.attrs;  @@attrs end

  end

  class DiskImageConfig
    include Builder
    attr_accessor :xml, :element
    def initialize xml, element
      @xml = xml
      @element = element
    end

    def config
      element.xpath('.//vmw:Config').reduce({}) do |acc,i|
        acc[i.attributes['key'].to_s] = i.attributes['value'].to_s
        acc
      end
    end

    def []= key,value
      config_item = @element.xpath('.//vmw:Config').select{ |e| e.attribute('key').value == key }.first
      config_item ||= create_item key,value
      config_item.set_attribute 'value', value
    end

    def [] key
      config[key]
    end

    def create_item key,value
      node = new_node 'vmw:Config', nil, {'vmw:key' => key, 'vmw:value' => value}
      @element << node
      node
    end
  end
end
