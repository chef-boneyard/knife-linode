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

# These two are needed for the '--purge' deletion case
require 'chef/node'
require 'chef/api_client'

class Chef
  class Knife
    class LinodeServerDelete < Chef::Knife

      include Knife::LinodeBase

      banner "knife linode server delete LINODE_ID|LINODE_LABEL (options)"

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the Linode node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."
        # :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the Linode node itself. The '--node-name' option also must be set to specify the Chef node and client to be removed."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."
        # :description => "The name of the node and client to delete.  Only has meaning when used with the '--purge' option."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run

        validate!

        @name_args.each do |linode_id|

          begin
            server = connection.servers.detect do |s|
              s.id.to_s == linode_id || s.name == linode_id
            end
            raise Fog::Compute::Linode::NotFound.new unless server
            delete_id = server.id

            msg_pair("Linode ID", server.id.to_s)
            msg_pair("Name", server.name)
            msg_pair("IPs", server.ips.map { |x| x.ip }.join(",") )
            msg_pair("Status", status_to_ui(server.status) )

            puts "\n"
            confirm("Do you really want to delete this server")

            connection.servers.get(delete_id).destroy

            ui.warn("Deleted server #{delete_id}")

            if config[:purge]
              if config[:chef_node_name]
                thing_to_delete = config[:chef_node_name]
              else
                thing_to_delete = server.name
              end
              destroy_item(Chef::Node, thing_to_delete, "node")
              destroy_item(Chef::ApiClient, thing_to_delete, "client")
            else
              ui.warn("Corresponding node and client for the #{linode_id} server were not deleted and remain registered with the Chef Server")
            end
          rescue Fog::Compute::Linode::NotFound
            ui.error("Could not locate server '#{linode_id}'.")
          end

        end

      end
    end
  end
end
