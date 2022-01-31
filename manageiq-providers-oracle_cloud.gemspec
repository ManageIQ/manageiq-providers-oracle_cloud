# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/providers/oracle_cloud/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-providers-oracle_cloud"
  spec.version       = ManageIQ::Providers::OracleCloud::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "ManageIQ plugin for the Oracle Cloud provider."
  spec.description   = "ManageIQ plugin for the Oracle Cloud provider."
  spec.homepage      = "https://github.com/ManageIQ/manageiq-providers-oracle_cloud"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "oci", "~> 2.16"

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "simplecov"
end
