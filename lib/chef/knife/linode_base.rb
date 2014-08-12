# rubocop:disable Style/Next
#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/knife'

class Chef
  class Knife
    module LinodeBase
      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
            require 'readline'
            require 'chef/json_compat'
          end

          option :linode_api_key,
                 short: '-A KEY',
                 long: '--linode-api-key KEY',
                 description: 'Your Linode API Key',
                 proc: proc { |key| Chef::Config[:knife][:linode_api_key] = key }

        end
      end

      def connection
        @connection ||= begin
          Fog::Compute.new(
            provider: 'Linode',
            linode_api_key: Chef::Config[:knife][:linode_api_key]
          )
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def msg_pair(label, value, color = :cyan)
        puts "#{ui.color(label, color)}: #{value}" if value && !value.empty?
      end

      def validate!(keys = [:linode_api_key])
        errors = []

        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/) { |w| (w =~ /(api)/i) ? w.upcase  : w.capitalize }
          if Chef::Config[:knife][k].nil?
            errors << "You did not provide a valid '#{pretty_key}' value."
          end
        end

        exit 1 if errors.each { |e| ui.error(e) }.any?
      end

      def status_to_ui(status)
        case status
        when -2
          ui.color('Boot Failed', :red)
        when -1
          ui.color('Being Created', :yellow)
        when 0
          ui.color('Brand New', :yellow)
        when 1
          ui.color('Running', :green)
        when 2
          ui.color('Powered Off', :red)
        when 3
          ui.color('Shutting Down', :red)
        else
          ui.color("UNKNOWN: #{server.status}", :yellow)
        end
      end
    end
  end
end
