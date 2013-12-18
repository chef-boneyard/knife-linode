
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife/linode_base'

class Chef
  class Knife
    class LinodeServerCreate < Knife

      include Knife::LinodeBase

       deps do
         require 'fog'
         require 'readline'
         require 'chef/json_compat'
         require 'chef/knife/bootstrap'
         Chef::Knife::Bootstrap.load_deps
       end

      banner "knife linode server create (options)"

      attr_accessor :initial_sleep_delay

      option :linode_flavor,
        :short => "-f FLAVOR",
        :long => "--linode-flavor FLAVOR",
        :description => "The flavor of server",
        :proc => Proc.new { |f| Chef::Config[:knife][:linode_flavor] = f },
        :default => 1 # Linode 1024

      option :linode_image,
        :short => "-I IMAGE",
        :long => "--linode-image IMAGE",
        :description => "The image for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:linode_image] = i },
        :default => 99 # Ubuntu 12.04 LTS

      option :linode_kernel,
        :short => "-k KERNEL",
        :long => "--linode-kernel KERNEL",
        :description => "The kernel for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:linode_kernel] = i },
        :default => 138 # Latest 64 bit

      option :linode_datacenter,
        :short => "-D DATACENTER",
        :long => "--linode-datacenter DATACENTER",
        :description => "The datacenter for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:linode_datacenter] = i },
        :default => 3 # Fremont, CA, USA

      option :linode_node_name,
        :short => "-L NAME",
        :long => "--linode-node-name NAME",
        :description => "The Linode node name for your new node"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      chars = ("a".."z").to_a + ("1".."9").to_a + ("A".."Z").to_a
      @@defpass = Array.new(20, '').collect{chars[rand(chars.size)]}.push('A').push('a').join

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :proc => Proc.new { |p| Chef::Config[:knife][:ssh_password] = p },
        :description => "The ssh password",
        :default => @@defpass

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "chef-full"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :json_attributes,
        :short => "-j JSON",
        :long => "--json-attributes JSON",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) }

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default",
        :boolean => true,
        :default => true

      Chef::Config[:knife][:hints] ||= {"linode" => {}}
      option :hint,
        :long => "--hint HINT_NAME[=HINT_FILE]",
        :description => "Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.",
        :proc => Proc.new { |h|
           name, path = h.split("=")
           Chef::Config[:knife][:hints][name] = path ? JSON.parse(::File.read(path)) : Hash.new
        }

      def tcp_test_ssh(hostname)
        Chef::Log.debug("testing ssh connection to #{hostname}")
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue SocketError
        Chef::Log.debug("SocketError, retrying")
        sleep 2
        false
      rescue Errno::ETIMEDOUT
        Chef::Log.debug("ETIMEDOUT, retrying")
        false
      rescue Errno::EPERM
        Chef::Log.debug("EPERM, retrying")
        false
      rescue Errno::ECONNREFUSED
        Chef::Log.debug("ECONNREFUSED, retrying")
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        Chef::Log.debug("EHOSTUNREACH, retrying")
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        $stdout.sync = true

        validate!

        datacenter_id = locate_config_value(:linode_datacenter).to_i
        datacenter = connection.data_centers.select { |dc| dc.id == datacenter_id }.first

        flavor = connection.flavors.get(locate_config_value(:linode_flavor).to_i)

        image = connection.images.get(locate_config_value(:linode_image).to_i)

        kernel = connection.kernels.get(locate_config_value(:linode_kernel).to_i)

        # FIXME: tweakable stack_script
        # FIXME: tweakable payment terms
        # FIXME: tweakable disk type

        server = connection.servers.create(
                    :data_center => datacenter,
                    :flavor => flavor,
                    :image => image,
                    :kernel => kernel,
                    :type => "ext3",
                    :payment_terms => 1,
                    :stack_script => nil,
                    :name => locate_config_value(:linode_node_name),
                    :password => locate_config_value(:ssh_password)
                 )

        fqdn = server.ips.select { |lip| !( lip.ip =~ /^192\.168\./ || lip.ip =~ /^10\./ || lip.ip =~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./ ) }.first.ip

        msg_pair("Linode ID", server.id.to_s)
        msg_pair("Name", server.name)
        msg_pair("IPs", server.ips.map { |x| x.ip }.join(",") )
        msg_pair("Status", status_to_ui(server.status) )
        msg_pair("Public IP", fqdn)
        msg_pair("User", config[:ssh_user])
        password = locate_config_value(:ssh_password)
        if password == @@defpass
          msg_pair("Password", password)
        end

        print "\n#{ui.color("Waiting for sshd", :magenta)}"

        print(".") until tcp_test_ssh(fqdn) {
          sleep @initial_sleep_delay ||= 10
          puts("done")
        }

        Chef::Config[:knife][:hints]['linode'] ||= Hash.new
        Chef::Config[:knife][:hints]['linode'].merge!({
            'server_id' => server.id.to_s,
            'datacenter_id' => locate_config_value(:linode_datacenter),
            'flavor_id' => locate_config_value(:linode_flavor),
            'image_id' => locate_config_value(:linode_image),
            'kernel_id' => locate_config_value(:linode_kernel),
            'ip_addresses' => server.ips.map(&:ip)})

        msg_pair("JSON Attributes", config[:json_attributes]) unless !config[:json_attributes] || config[:json_attributes].empty?
        bootstrap_for_node(server,fqdn).run
      end

      def bootstrap_for_node(server,fqdn)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [fqdn]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        bootstrap
      end

    end
  end
end
