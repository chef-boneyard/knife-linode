
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
    class LinodeServerCreate < Chef::Knife

      include Knife::LinodeBase

      # deps do
      #   require 'fog'
      #   require 'readline'
      #   require 'chef/json_compat'
      #   require 'chef/knife/bootstrap'
      #   Chef::Knife::Bootstrap.load_deps
      # end

      banner "knife linode server create (options)"

      attr_accessor :initial_sleep_delay

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server",
        :proc => Proc.new { |f| Chef::Config[:knife][:linode_flavor] = f },
        :default => 1

      option :image,
        :short => "-I IMAGE",
        :long => "--image IMAGE",
        :description => "The image for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:linode_image] = i },
        :default => 83

      option :kernel,
        :short => "-k IMAGE",
        :long => "--kernel IMAGE",
        :description => "The kernel for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:linode_kernel] = k },
        :default => 133

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :proc => Proc.new { |p| Chef::Config[:knife][:ssh_password] = p },
        :description => "The ssh password",
        :default => "BarbaZ"

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
        :default => "ubuntu10.04-gems"

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

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false

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
        validate!

        datacenter = connection.data_centers.select { |dc| dc.id == 3 }.first

        flavor = connection.flavors.get(locate_config_value(:linode_flavor))

        image = connection.images.get(locate_config_value(:linode_image))

        kernel = connection.kernels.get(locate_config_value(:linode_kernel))

        server = connection.servers.create(:data_center => datacenter, :flavor => flavor, :image => image, :kernel => kernel, :type => "ext3", :payment_terms => 1, :stack_script => nil , :name => "foo", :password => locate_config_value(:ssh_password))

        print "\n#{ui.color("Waiting for sshd", :magenta)}"

        fqdn = server.ips.select { |lip| !( lip.ip =~ /^192\.168\./ || lip.ip =~ /^10\./ || lip.ip =~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./ ) }.first.ip

        print(".") until tcp_test_ssh(fqdn) {
          sleep @initial_sleep_delay ||= 10
          puts("done")
        }
 
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
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]
        bootstrap.config[:no_host_key_verify] = config[:no_host_key_verify]
        bootstrap
      end

    end
  end
end
