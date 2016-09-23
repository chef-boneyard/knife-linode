
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

require "chef/knife/linode_base"

class Chef
  class Knife
    class LinodeServerList < Chef::Knife

      include Knife::LinodeBase

      banner "knife linode server list (options)"

      def run
        $stdout.sync = true

        validate!

        server_list = [
          ui.color("Linode ID", :bold),
          ui.color("Name", :bold),
          ui.color("IPs", :bold),
          ui.color("Status", :bold),
          ui.color("Backups", :bold),
          ui.color("Datacenter", :bold),
        ]

        dc_location = {}

        connection.data_centers.map { |dc| dc_location[dc.id] = dc.location }

        connection.servers.each do |server|
          server_list << server.id.to_s
          server_list << server.name
          server_list << server.ips.map { |x| x.ip }.join(",")
          server_list << status_to_ui(server.status)
          server_list << case connection.linode_list(server.id).body["DATA"][0]["BACKUPSENABLED"]
                         when 0
                           ui.color("No", :red)
                         when 1
                           ui.color("Yes", :green)
                         else
                           ui.color("UNKNOWN", :yellow)
                         end
          server_list << dc_location[connection.linode_list(server.id).body["DATA"][0]["DATACENTERID"]]
        end

        puts ui.list(server_list, :columns_across, 6)
      end
    end
  end
end
