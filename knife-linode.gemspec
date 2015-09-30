# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-linode/version"

Gem::Specification.new do |s|
  s.name        = "knife-linode"
  s.version     = Knife::Linode::VERSION
  s.authors     = ['Adam Jacob', 'Seth Chisamore', 'Lamont Granquist', 'Jesse R. Adams']
  s.email       = ['adam@opscode.com', 'schisamo@opscode.com', 'lamont@opscode.com', 'jesse@techno-geeks.org']
  s.homepage    = 'https://github.com/chef/knife-linode'
  s.summary     = "Linode Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ['README.md', 'LICENSE']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "fog",  "~> 1.0"
  s.add_runtime_dependency "chef", ">= 11.8"

  s.add_development_dependency "rspec",   "~> 3.0"
  s.add_development_dependency "rubocop",    "~> 0.24"
end
