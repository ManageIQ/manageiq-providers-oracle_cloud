$:.push(File.expand_path("../lib", __FILE__))

require "manageiq/providers/oracle_cloud/version"

Gem::Specification.new do |s|
  s.name        = "manageiq-providers-oracle_cloud"
  s.version     = ManageIQ::Providers::OracleCloud::VERSION
  s.authors     = ["ManageIQ Developers"]
  s.homepage    = "https://github.com/ManageIQ/manageiq-providers-oracle_cloud"
  s.summary     = "OracleCloud Provider for ManageIQ"
  s.description = "OracleCloud Provider for ManageIQ"
  s.licenses    = ["Apache-2.0"]

  s.files = Dir["{app,config,lib}/**/*"]

  s.add_dependency("fog-oraclecloud")

  s.add_development_dependency("codeclimate-test-reporter", "~> 1.0.0")
  s.add_development_dependency("simplecov")
end
