
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

# requires ruby 1.9.2

class Chef
  class Knife
    class LinodeServerList < Chef::Knife

      include Knife::LinodeBase

      banner "knife linode server list (options)"

      def run

        $stdout.sync = true

        validate!

        server_list = [
          ui.color('Linode ID', :bold),
          ui.color('Name', :bold),
          ui.color('IPs', :bold),
          ui.color('Status', :bold),
        ]

        connection.servers.each do |server|
          server_list << server.id.to_s
          server_list << server.name
          server_list << server.ips.map { |x| x.ip }.join(",")
          server_list << begin
            case server.status
            when -2
              ui.color("Boot Failed", :red)
            when -1
              ui.color("Being Created", :yellow)
            when 0
              ui.color("Brand New", :yellow)
            when 1
              ui.color("Running", :green)
            when 2
              ui.color("Powered Off", :red)
            when 3
              ui.color("Shutting Down", :red)
            else
              ui.color("UNKNOWN: #{server.status}", :yellow)
            end
          end
        end

        puts ui.list(server_list, :columns_across, 4)

      end
    end
  end
end
