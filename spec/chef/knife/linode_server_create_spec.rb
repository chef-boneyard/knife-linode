require 'spec_helper'
require 'linode_server_create'

class MockSocket < BasicSocket
  def initialize; end
  def gets; end
  def close; end
end

describe Chef::Knife::LinodeServerCreate do
  subject { Chef::Knife::LinodeServerCreate.new }

  let(:api_key)     { 'FAKE_API_KEY' }
  let(:mock_socket) { MockSocket.new }

  before :each do
    Chef::Knife::LinodeServerCreate.load_deps
    Chef::Config[:knife][:linode_api_key] = api_key
    allow(subject).to receive(:puts)
    allow(subject).to receive(:print)
  end

  describe "#tcp_test_ssh" do
    let(:empty_block) { lambda {} }

    before :each do
      allow(TCPSocket).to receive(:new).and_return(mock_socket)
    end

    it "should open a socket to the host on port 22" do
      hostname = "foo.example.com"
      expect(IO).to receive(:select).with([mock_socket], anything(), anything(), anything()).and_return([mock_socket])
      expect(TCPSocket).to receive(:new).with(hostname, 22).and_return(mock_socket)
      subject.tcp_test_ssh(hostname, &empty_block)
    end

    it "should return true if the socket is listening" do
      allow(IO).to receive(:select).with([mock_socket], anything(), anything(), anything()).and_return([mock_socket])
      expect(subject.tcp_test_ssh("foo.example.com", &empty_block)).to be_truthy
    end

    it "should return false if the socket is NOT listening" do
      allow(IO).to receive(:select).with([mock_socket], anything(), anything(), anything()).and_return(nil)
      expect(subject.tcp_test_ssh("foo.example.com", &empty_block)).to be_falsey
    end

    # TODO: Add more specs for behavior of rescue blocks
  end

  describe "#run" do
    let(:mock_bootstrap) {
      double("Chef::Knife::Bootstrap").tap do |mb|
        allow(mb).to receive(:run)
        allow(mb).to receive(:name_args=)
        allow(mb).to receive(:config).and_return({})
      end
    }

    let(:mock_server) {
      double("Fog::Compute::Linode::Server").tap do |ms|
        allow(ms).to receive(:ips).and_return([mock_ip("1.2.3.4")])
        allow(ms).to receive(:id).and_return(42)
        allow(ms).to receive(:name).and_return("Test Linode")
        allow(ms).to receive(:status).and_return(1)
      end
    }

    let(:mock_servers) {
      double("Fog::Collection").tap do |ms|
        allow(subject.connection).to receive(:servers).and_return(ms)
      end
    }

    before :each do
      allow(Chef::Knife::Bootstrap).to receive(:new).and_return(mock_bootstrap)
      allow(subject).to receive(:tcp_test_ssh).and_return(true)
      allow(mock_servers).to receive(:create).and_return(mock_server)
      allow(subject.connection).to receive(:servers).and_return(mock_servers)
    end

    it "should validate the Linode config keys exist" do
      expect(subject).to receive(:validate!)
      subject.run
    end

    it "should call #create on the servers collection with the correct params" do
      skip 'fails - arg variable does not exist'

      configure_chef(subject)

      expect(mock_servers).to receive(:create) { |server|
        server.each do |k,v|
          case k
          when :data_center, :flavor, :image, :kernel
            expect(arg[k].id.to_i).to eq(v.id)
          else
            expect(arg[k]).to eq(v)
          end
        end
      }.and_return(mock_server)

      subject.run
    end

    it "should create a Chef::Knife::Bootstrap instance" do
      expect(Chef::Knife::Bootstrap).to receive(:new)
      subject.run
    end

    it "should set the bootstrap name_args to the Linode's public IP" do
      ips = %w( 1.2.3.4 192.168.1.1 ).map { |ip| mock_ip(ip) }
      allow(mock_server).to receive(:ips).and_return(ips)
      expect(mock_bootstrap).to receive(:name_args=).with([ips.first.ip])

      subject.run
    end

    it "should set the bootstrap config correctly" do
      mock_config = {}
      allow(mock_bootstrap).to receive(:config).and_return(mock_config)

      chef_config = configure_chef(subject)

      params = [
        :run_list, :ssh_user, :identity_file, :ssh_password, :chef_node_name,
        :prerelease, :bootstrap_version, :distro, :use_sudo, :template_file,
        :environment, :no_host_key_verify
      ]

      subject.run

      params.each do |param|
        case param
        when :use_sudo
          expect(mock_config[:use_sudo]).to be_falsey
        else
          expectation = chef_config[param]
          actual = mock_config[param]

          if actual != expectation
            $stderr.puts "#{param}: #{actual.inspect} should have been #{expectation.inspect}"
          end

          expect(actual).to eq(expectation)
        end
      end
    end
  end
end

def mock_ip(ip)
  OpenStruct.new(:ip => ip)
end

def configure_chef(subject)
  connection = subject.connection
  server = {
    :data_center   => connection.data_centers.first,
    :flavor        => connection.flavors.first,
    :image         => connection.images.first,
    :kernel        => connection.kernels.first,
    :type          => "ext3",
    :payment_terms => 1,
    :stack_script  => nil,
    :name          => "test_node",
    :password      => nil,
  }

  chef_config = {
    :ssh_user       => "root",
    :run_list       => [],
    :identity_file  => "~/.ssh/id_dsa",
    :chef_node_name => "test_node",
    :environment    => "_test",
  }

  server_params = {}
  server.each do |k,v|
    case k
    when :data_center
      server_params[:datacenter] = v.id
    when :data_center, :flavor, :image, :kernel
      server_params[k] = v.id
    else
      server_params[k] = v
    end
  end

  # setup the config before we call #run
  server_params.each do |k,v|
    case k
    when :name
      Chef::Config[:knife][:linode_node_name] = v
    when :password
      Chef::Config[:knife][:ssh_password] = v
    when :type, :payment_terms, :stack_script
      # these are hard-coded in the plugin, so don't add them to the Config
    when :name
      Chef::Config[:knife][:linode_node_name] = v
      Chef::Config[:knife][:chef_node_name] = v
    when :datacenter, :flavor, :image, :kernel
      Chef::Config[:knife]["linode_#{k}".to_sym] = v
    else
      Chef::Config[:knife][k] = v
    end
  end

  cli_config = subject.config.dup
  chef_config.each do |k,v|
    cli_config[k] = v
  end
  allow(subject).to receive(:config).and_return(cli_config)
  #cli_config.merge(Chef::Config[:knife].dup)
  cli_config
end
