describe Rovfer::Parser do

  let(:ovf_path) { 'spec/fixtures/base-build3.ovf' }
  let(:parser) { Rovfer::Parser.new(open( ovf_path )) }
  it 'can parse an ovf xml file' do
    expect(parser.references).to include('base-build3-disk1.vmdk')
  end

  it 'can format an xpath query' do
    expect(parser.get_in_envelope('References','File')).to eql( "/xmlns:Envelope/xmlns:References/xmlns:File" )
  end

  it "has disks" do
    expect(parser.disks).to_not be_nil
  end

  it 'has networks' do
    expect(parser.networks).to eql(['NAT'])
  end

  it 'can set networks' do
    expect{parser.networks = ['OTHER'] }.
      to change{parser.networks}
  end

  it 'has an os_type' do
    expect(parser.os_type).to eql('rhel6_64Guest')
  end

  it 'has a ram size' do
    expect( parser.ram.to_i ).to be > 0
  end

  it 'has a scsi_controller_type' do
    expect( parser.scsi_controller_type ).to eql('VirtualSCSI')
  end

  it 'has a disk image' do
    expect( parser.disk_image_parent_id ).to eql('5')
  end

  context 'writing a file' do
    before do
      FileUtils.cp(ovf_path, ovf_path + '_tmp')
    end
    after do
      FileUtils.mv(ovf_path + '_tmp', ovf_path)
    end
    it 'can reload the xml from disk' do
      version = parser.xml.children.first.attributes['version']
      version.value = '1.5'
      expect{ parser.reload }.to change{ parser.xml.children.first.attributes['version'].value }
    end

    it 'can save the xml to disk' do
      version = parser.xml.children.first.attributes['version']
      version.value = '1.5'
      parser.save
      expect{ parser.reload }.to_not change{ parser.xml.children.first.attributes['version'].value }
    end

    it 'can save network changes correctly' do
      parser.networks = ['OTHER']
      parser.save
      parser.reload
      expect( parser.networks ).to eql( ['OTHER'] )
    end

    it 'can save the os_type correctly' do
      parser.set_os_type 'Centos', '6', 'Hello'
      parser.save
      parser.reload
      expect( parser.os_type ).to eql( 'Centos' )
    end

    it 'can save the VirtualSystemType correctly' do
      parser.system_type = 'vmx-09'
      parser.save
      parser.reload
      expect( parser.system_type ).to eql( 'vmx-09' )
    end

    it 'can save the ram correctly' do
      parser.ram = 1024
      parser.save
      parser.reload
      expect(parser.ram).to eql('1024')
    end

    it 'can save the scsci_controller_type correctly' do
      parser.scsi_controller_type= 'VirtualSCSI-something'
      parser.save
      parser.reload
      expect(parser.scsi_controller_type).to eql('VirtualSCSI-something')
    end

    it 'can save the special vmware config' do
      parser.add_special_vmw_config
      expect( parser.xml.xpath('//xmlns:VirtualSystem/xmlns:VirtualHardwareSection/vmw:Config').count ).to be >= (17)
    end

  end
end
