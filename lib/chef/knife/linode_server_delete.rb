
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
    class LinodeServerDelete < Chef::Knife

      include Knife::LinodeBase

      banner "knife linode server delete (options)"

      def run

        validate!

        @name_args.each do |linode_id|

          begin
            server = connection.servers.get(linode_id)

            msg_pair("Linode ID", server.id)
            msg_pair("Name", server.name)
            msg_pair("IPs", server.ips.map { |x| x.ip }.join(",") )
            msg_pair("Status", status_to_ui(server.status) )

            puts "\n"
            confirm("Do you really want to delete this server")

            connection.servers.get(linode_id).destroy

            ui.warn("Deleted server #{linode_id}")
          rescue Fog::Compute::Linode::NotFound
            ui.error("Could not locate server '#{linode_id}'.")
          end

        end

      end
    end
  end
end
