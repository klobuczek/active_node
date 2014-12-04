# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_node/version"

Gem::Specification.new do |s|
  s.name        = "active_node"
  s.version     = ActiveNode::VERSION
  s.authors     = ["Heinrich Klobuczek"]
  s.email       = ["heinrich@mail.com"]
  s.homepage    = ""
  s.summary     = "ActiveRecord style Object Graph Mapping for neo4j"
  s.description = "ActiveRecord style Object Graph Mapping for neo4j"

  s.rubyforge_project = "active_node"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "active_attr"
  s.add_dependency "neography"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake", ">= 0.8.7"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "codeclimate-test-reporter"
end
