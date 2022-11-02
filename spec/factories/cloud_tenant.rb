FactoryBot.define do
  factory :cloud_tenant_oracle_cloud, :parent => :cloud_tenant, :class => "ManageIQ::Providers::OracleCloud::CloudManager::CloudTenant"
end
