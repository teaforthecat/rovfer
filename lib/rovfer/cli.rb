module Rovfer::CLI
  class Base < Thor

    option :networks, type: :array
    def to_vmware(path)
      new,bkup = File.expand_path( path ).tap{ |p| [p, p + '.bkup'] }
      FileUtils.cp file_path, bkup
      say "wrote backup #{bkup}", :green
      parser = Rovfer::Parser.new path
      parser.networks = options[:networks] if options[:networks]
      parser.system_type = 'vmx-09'
      parser.scsi_controller_type= 'VirtualSCSI'
      parser.disk_image_config['backing.writeThrough'] = true #not sure what this does
      parser.add_special_vmware_config #hot resize ram values and such
      parser.save #overwrites the ovf file
      say "wrote edited ovf #{new}", :green
    end
  end
end
