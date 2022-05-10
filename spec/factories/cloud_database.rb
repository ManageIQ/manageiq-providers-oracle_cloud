FactoryBot.define do
  factory :cloud_database_oracle,
          :class => "ManageIQ::Providers::OracleCloud::CloudManager::CloudDatabase"
end
