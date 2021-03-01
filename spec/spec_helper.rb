if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

require "manageiq-providers-oracle_cloud"

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::OracleCloud::Engine.root, 'spec/vcr_cassettes')
  config.define_cassette_placeholder("ocid1.user.oc1..aaaaaaaa") { Rails.application.secrets.oracle_cloud[:user_id] }
  config.define_cassette_placeholder("ocid1.tenancy.oc1..aaaaaaaa") { Rails.application.secrets.oracle_cloud[:tenant_id] }
end
