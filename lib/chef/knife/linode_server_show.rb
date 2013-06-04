
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
    class LinodeServerShow < Chef::Knife

      include Knife::LinodeBase

      banner "knife linode server show ID (options)"

      def run

        dc_location = {}
        flavors = []
        connection.data_centers.map { |dc| dc_location[dc.id] = dc.location }

        connection.flavors.each do |flavor|
          flavors << {:id => flavor.id, :name=> flavor.name, :ram => flavor.ram,
            :disk=> flavor.disk, :price => flavor.price }
        end

        validate!
        server = connection.servers.get(@name_args.first)
        server_data = Hash.new
        server_data[:attributes] = server.attributes
        server_data[:linode_id] = server.id
        server_data[:name] = server.name
        server_data[:ips] = server.ips.map { |x| x.ip }.join(",")
        server_data[:status] = server.status
        server_data[:backups] = connection.linode_list(server.id).body['DATA'][0]['BACKUPSENABLED']
        server_data[:datacenter_id] = connection.linode_list(server.id).body['DATA'][0]['DATACENTERID']
        server_data[:datacenter_location] =dc_location[connection.linode_list(server.id).body['DATA'][0]['DATACENTERID']]
        flavor =  flavors.select{|f| f[:ram] == server.attributes[:totalram] }
        unless flavor.empty?
          server_data[:flavor] = flavor.first
        else
          ui.warn("Cant detect the flavor of linode srevre (id:#{server.id})")
          ui.warn("Total ram: #{server.attributes[:totalram]}")
        end
        ui.output(server_data)
      end
    end
  end
end
