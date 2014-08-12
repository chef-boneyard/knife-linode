require 'spec_helper'
require 'linode_datacenter_list'

describe Chef::Knife::LinodeDatacenterList do
  subject { Chef::Knife::LinodeDatacenterList.new }

  let(:api_key) { 'FAKE_API_KEY' }

  before :each do
    Chef::Knife::LinodeDatacenterList.load_deps
    Chef::Config[:knife][:linode_api_key] = api_key
    allow(subject).to receive(:puts)
  end

  describe '#run' do
    it 'should validate the Linode config keys exist' do
      expect(subject).to receive(:validate!)
      subject.run
    end

    it 'should output the column headers' do
      expect(subject).to receive(:puts).with(/^ID\s+Location\s*$/)
      subject.run
    end

    it 'should output the datacenter locations' do
      expect(subject).to receive(:puts).with(/(?:Newark|Tokyo|Dallas)/)
      subject.run
    end
  end
end
