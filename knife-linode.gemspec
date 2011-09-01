# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-linode/version"

Gem::Specification.new do |s|
  s.name        = "knife-linode"
  s.version     = Knife::Linode::VERSION
  s.has_rdoc = true
  s.authors     = ["Adam Jacob","Seth Chisamore", "Lamont Granquist"]
  s.email       = ["adam@opscode.com","schisamo@opscode.com", "lamont@opscode.com"]
  s.homepage = "http://wiki.opscode.com/display/chef"
  s.summary = "Linode Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency "fog", "~> 0.11.0"
  s.require_paths = ["lib"]

end
