FactoryBot.define do
  factory :cloud_network_oracle_cloud, :parent => :cloud_network, :class => "ManageIQ::Providers::OracleCloud::NetworkManager::CloudNetwork"
end
