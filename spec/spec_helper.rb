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

  config.define_cassette_placeholder(Rails.application.secrets.oracle_cloud_defaults[:user_id]) do
    Rails.application.secrets.oracle_cloud[:user_id]
  end
  config.define_cassette_placeholder(Rails.application.secrets.oracle_cloud_defaults[:tenant_id]) do
    Rails.application.secrets.oracle_cloud[:tenant_id]
  end
end
