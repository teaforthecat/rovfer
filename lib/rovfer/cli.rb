require 'thor'
require 'rovfer/parser'

module Rovfer::CLI
  class Base < Thor

    desc 'to_vmware PATH_TO_OVF', 'cp bkup, then edit xml for vmware'
    option :networks, type: :array
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
      parser.system_type = 'vmx-09'
      parser.scsi_controller_type= 'VirtualSCSI'
      parser.disk_image_config['backing.writeThrough'] = true #not sure what this does
      parser.add_special_vmware_config #hot resize ram values and such
      parser.save #overwrites the ovf file
      say "wrote edited ovf #{xml_path}", :green
    end
  end
end
