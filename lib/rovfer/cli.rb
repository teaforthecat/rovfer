require 'thor'
require 'rovfer/parser'

module Rovfer::CLI
  class Base < Thor

    desc 'to_vmware PATH_TO_OVF', 'cp bkup, then edit xml for vmware'
    option :networks, type: :array
    option :system_type, default: 'vmx-09', desc: 'vsphere version/compatibility'
    option :scsi_controller_type, default: 'VirtualSCSI'
    def to_vmware(path)
      xml_path = File.expand_path( path )
      bkup     =  xml_path + '.bkup'
      if File.exists?(bkup) && no?('overwrite existing bkup?:')
        raise Thor::Error.new('nothing done')
      end
      FileUtils.cp xml_path, bkup
      say "wrote backup #{bkup}", :green
      parser = Rovfer::Parser.new xml_path
      parser.networks = options[:networks] if options[:networks]
      parser.system_type = options.fetch(:system_type)
      parser.scsi_controller_type= options.fetch(:scsi_controller_type)
      parser.disk_image_config['backing.writeThrough'] = true #not sure what this does, but it was set in an export
      parser.add_special_vmware_config #hot resize ram values and such
      parser.save #overwrites the ovf file
      say "wrote edited ovf #{xml_path}", :green
    end
  end
end
