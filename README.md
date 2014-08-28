# Rovfer

Open Virtualization Format Xml Editor
For transating features between virtualization providers, mainly virtualbox -> vsphere.

## Installation

Add this line to your application's Gemfile:

    gem 'rovfer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rovfer

## Usage

    parser = Rovfer::Parser.new "path/to/exported/vm.ovf"
    parser.networks = ['PRODUCTION']
    parser.system_type = 'vmx-09'
    parser.set_os_type 'Centos', '6', 'Centos 6 Minimal'
    parser.ram = 1024 # in megabytes
    parser.scsi_controller_type= 'VirtualSCSI'
    parser.add_special_vmware_config
    parser.save #overwrites the ovf file

## Contributing

1. Fork it ( http://github.com/teaforthecat/rovfer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
