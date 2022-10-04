FactoryBot.define do
  factory :flavor_oracle_cloud, :parent => :flavor, :class => "ManageIQ::Providers::OracleCloud::CloudManager::Flavor"
end
