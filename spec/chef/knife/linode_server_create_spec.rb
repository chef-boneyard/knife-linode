require 'spec_helper'
require 'linode_server_create'

class MockSocket < BasicSocket
  def initialize
  end

  def gets
  end

  def close
  end
end

describe Chef::Knife::LinodeServerCreate do
  subject { Chef::Knife::LinodeServerCreate.new }

  let(:api_key) { 'FAKE_API_KEY' }
  let(:mock_socket) { MockSocket.new }

  before :each do
    Chef::Knife::LinodeServerCreate.load_deps
    Chef::Config[:knife][:linode_api_key] = api_key
    subject.stub(:puts)
    subject.stub(:print)
  end

  describe "#tcp_test_ssh" do
    let(:empty_block) { lambda {} }

    before :each do
      TCPSocket.stub(:new).with(anything(), 22).and_return(mock_socket)
    end

    it "should open a socket to the host on port 22" do
      hostname = "foo.example.com"
      IO.should_receive(:select).with([mock_socket], anything(), anything(), anything()).and_return([mock_socket])
      TCPSocket.should_receive(:new).with(hostname, 22).and_return(mock_socket)
      subject.tcp_test_ssh(hostname, &empty_block)
    end

    it "should return true if the socket is listening" do
      IO.stub(:select).with([mock_socket], anything(), anything(), anything()).and_return([mock_socket])
      subject.tcp_test_ssh("foo.example.com", &empty_block).should be_true
    end

    it "should return false if the socket is NOT listening" do
      IO.stub(:select).with([mock_socket], anything(), anything(), anything()).and_return(nil)
      block = lambda {
        # nothing
      }
      subject.tcp_test_ssh("foo.example.com", &empty_block).should be_false
    end

    # TODO: Add more specs for behavior of rescue blocks
  end

  describe "#run" do
    let(:mock_bootstrap) {
      mock("Chef::Knife::Bootstrap").tap do |mb|
        mb.stub(:run)
        mb.stub(:name_args=)
        mb.stub(:config).and_return({})
      end
    }

    let(:mock_server) {
      mock("Fog::Compute::Linode::Server").tap do |ms|
        ms.stub(:ips).and_return([mock_ip("1.2.3.4")])
        ms.stub(:id).and_return(42)
        ms.stub(:name).and_return("Test Linode")
        ms.stub(:status).and_return(1)
      end
    }

    let(:mock_servers) {
      mock("Fog::Collection").tap do |ms|
        subject.connection.stub(:servers).and_return(ms)
      end
    }

    before :each do
      Chef::Knife::Bootstrap.stub(:new).and_return(mock_bootstrap)
      subject.stub(:tcp_test_ssh).and_return(true)
      mock_servers.stub(:create).and_return(mock_server)
      subject.connection.stub(:servers).and_return(mock_servers)
    end

    it "should validate the Linode config keys exist" do
      subject.should_receive(:validate!)
      subject.run
    end

    it "should call #create on the servers collection with the correct params" do
      configure_chef(subject)

      ### expectation block
      mock_servers.should_receive(:create) { |arg|
        server.each do |k,v|
          case k
          when :data_center, :flavor, :image, :kernel
            arg[k].id.to_i.should == v.id
          else
            arg[k].should == v
          end
        end
      }.and_return(mock_server)

      ### run the code we're testing
      subject.run
    end

    it "should create a Chef::Knife::Bootstrap instance" do
      Chef::Knife::Bootstrap.should_receive(:new)
      subject.run
    end

    it "should set the bootstrap name_args to the Linode's public IP" do
      ips = %w( 1.2.3.4 192.168.1.1 ).map { |ip| mock_ip(ip) }
      mock_server.stub(:ips).and_return(ips)

      mock_bootstrap.should_receive(:name_args=).with([ips.first.ip])

      subject.run
    end

    it "should set the bootstrap config correctly" do
      mock_config = {}
      mock_bootstrap.stub(:config).and_return(mock_config)

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
          mock_config[:use_sudo].should be_false
        else
          expectation = chef_config[param]
          reality = mock_config[param]

          if reality != expectation
            $stderr.puts "#{param}: #{reality.inspect} should have been #{expectation.inspect}"
          end

          reality.should == expectation
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
    :password      => "p4ssw0rd",
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
  subject.stub(:config).and_return(cli_config)

  cli_config.merge(Chef::Config[:knife].dup)
end
