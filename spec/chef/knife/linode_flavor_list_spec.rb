require 'spec_helper'
require 'linode_flavor_list'

describe Chef::Knife::LinodeFlavorList do
  subject { Chef::Knife::LinodeFlavorList.new }

  let(:api_key) { 'FAKE_API_KEY' }

  before :each do
    Chef::Knife::LinodeFlavorList.load_deps
    Chef::Config[:knife][:linode_api_key] = api_key
    subject.stub!(:puts)
  end

  describe "#run" do
    it "should validate the Linode config keys exist" do
      subject.should_receive(:validate!)
      subject.run
    end

    it "should output the column headers" do
      subject.should_receive(:puts).with(/^ID\s+Name\s+RAM\s+Disk\s+Price\s*$/)
      subject.run
    end

    it "should output a list of the available Linode flavors" do
      subject.should_receive(:puts).with(/\bLinode \d+\b/)
      subject.run
    end
  end
end
