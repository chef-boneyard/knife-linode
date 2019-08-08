# Knife Linode

[![Gem Version](https://badge.fury.io/rb/knife-linode.svg)](https://rubygems.org/gems/knife-linode) [![Build Status](https://travis-ci.org/chef/knife-linode.svg?branch=master)](https://travis-ci.org/chef/knife-linode)

* **Umbrella Project: [Knife](https://github.com/chef/chef-oss-practices/blob/master/projects/knife.md)**

* **Project State [Deprecated](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#deprecated)**

* **Issues [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#what-is-the-response-time-maximum): None**

* **Pull Request [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#what-is-the-response-time-maximum): None**

## Description

This is the official Chef Knife plugin for Linode. This plugin gives knife the ability to create, bootstrap, and manage Linode instances.

## Requirements

- Chef 12.0 higher
- Ruby 2.2.2 or higher

## Installation

Using [ChefDK](https://downloads.chef.io/chef-dk/), simply install the Gem:

```bash
$ chef gem install knife-linode
```

## Configuration

### knife.rb

In order to communicate with the Linode API you will have to tell Knife about your Linode API Key. The easiest way to accomplish this is to create some entries in your `knife.rb` file:

```ruby
knife[:linode_api_key] = "Your Linode API Key"
```

If your knife.rb file will be checked into a SCM system (ie readable by others) you may want to read the values from environment variables:

```ruby
knife[:linode_api_key] = "#{ENV['LINODE_API_KEY']}"
```

You also have the option of passing your Linode API Key into the individual knife subcommands using the `-A` (or `--linode-api-key`) command option

```
# Provision a new 1 GB 64 bit Ubuntu 14.04 Linode in the Dallas, TX datacenter
knife linode server create -r 'role[webserver]' --linode-image 124 --linode-datacenter 2 --linode-flavor 1 --linode-node-name YOUR_LINODE_NODE_NAME
```

Additionally the following options may be set in your `knife.rb`:

- linode_flavor
- linode_image
- linode_kernel
- ssh_password
- bootstrap_version
- distro
- template_file

## Knife Sub Commands

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a `--help` flag

### knife linode server create

Provisions a new server in Linode and then perform a Chef bootstrap (using the SSH protocol). The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists (provided by the provisioning). It is primarily intended for Chef Client systems that talk to a Chef server. By default the server is bootstrapped using the [ubuntu10.04-gems](https://github.com/opscode/chef/blob/master/chef/lib/chef/k
nife/bootstrap/ubuntu10.04-gems.erb) template. This can be overridden using the `-d` or `--template-file` command options.

### knife linode server delete

Deletes an existing server in the currently configured Linode account. **PLEASE NOTE** - this does not delete the associated node and client objects from the Chef server.

### knife linode server list

Outputs a list of all servers in the currently configured Linode account. **PLEASE NOTE** - this shows all instances associated with the account, some of which may not be currently managed by the Chef server.

### knife linode server reboot

Reboots an existing server in the currently configured Linode account.

### knife linode datacenter list

View a list of available data centers, listed by data center ID and location.

### knife linode flavor list

View a list of servers from the Linode environment, listed by ID, name, RAM, disk, and Price.

### knife linode image list

View a list of images from the Linode environment, listed by ID, name, bits, and image size.

### knife linode kernel list

View a a list of available kernels, listed by ID and name.

### knife linode stackscript list

View a list of Linode StackScripts that are currently being used.

## Contributing

For information on contributing to this project see <https://github.com/chef/chef/blob/master/CONTRIBUTING.md>

## License and Authors

- Author:: Adam Jacob ([adam@chef.io](mailto:adam@chef.io))
- Author:: Jesse Adams ([jesse@techno-geeks.org](mailto:jesse@techno-geeks.org))

```text
Copyright 2009-2016 Chef Software, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
