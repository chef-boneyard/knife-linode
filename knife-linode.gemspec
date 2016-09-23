# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-linode/version"

Gem::Specification.new do |s|
  s.name        = "knife-linode"
  s.version     = Knife::Linode::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Jacob", "Seth Chisamore", "Lamont Granquist", "Jesse R. Adams"]
  s.email       = ["adam@chef.io", "schisamo@chef.io", "lamont@chef.io", "jesse@techno-geeks.org"]
  s.license     = "Apache-2.0"
  s.has_rdoc    = true
  s.homepage    = "https://github.com/chef/knife-linode"
  s.summary     = "Linode Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.md", "LICENSE"]

  s.required_ruby_version = ">= 2.2.2"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "fog",  "~> 1.0"
  s.add_runtime_dependency "chef", ">= 12.0"

  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "chefstyle"
end
