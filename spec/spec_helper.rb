if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

require "manageiq/providers/oracle_cloud"

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::OracleCloud::Engine.root, 'spec/vcr_cassettes')

  secrets = Rails.application.secrets
  secrets.oracle_cloud.each do |key, val|
    config.define_cassette_placeholder(secrets.oracle_cloud_defaults[key]) { val }
  end
  secrets.oracle_oke.each do |key, val|
    config.define_cassette_placeholder(secrets.oracle_oke_defaults[key]) { val }
  end
end
