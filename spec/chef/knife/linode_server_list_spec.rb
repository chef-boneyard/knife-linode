require 'spec_helper'
require 'linode_server_list'

describe Chef::Knife::LinodeServerList do
  subject { Chef::Knife::LinodeServerList.new }

  let(:api_key) { 'FAKE_API_KEY' }

  before :each do
    Chef::Knife::LinodeServerList.load_deps
    Chef::Config[:knife][:linode_api_key] = api_key
    allow(subject).to receive(:puts)
  end

  describe '#run' do
    it 'should validate the Linode config keys exist' do
      expect(subject).to receive(:validate!)
      subject.run
    end

    it 'should output the column headers' do
      expect(subject).to receive(:puts).with(/^Linode ID\s+Name\s+IPs\s+Status\s+Backups\s+Datacenter\s*$/)
      subject.run
    end

    it 'should output a list of the server labels' do
      expect(subject).to receive(:puts).with(/\btest_\d+\b/)
      subject.run
    end

    it 'should output a list of the server IPs' do
      expect(subject).to receive(:puts).with(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)
      subject.run
    end

    it 'should output the running state of the servers' do
      expect(subject).to receive(:puts).with(/\bRunning\b/)
      subject.run
    end

    it 'should output the datacenter location of the servers' do
      expect(subject).to receive(:puts).with(/\bNewark, NJ, USA\b/)
      subject.run
    end
  end
end
