FactoryBot.define do
  factory :vm_oracle, :class => "ManageIQ::Providers::OracleCloud::CloudManager::Vm", :parent => :vm_cloud do
    vendor { "oracle" }
  end

  factory :template_oracle, :class => "ManageIQ::Providers::OracleCloud::CloudManager::Template", :parent => :template_cloud do
    vendor { "oracle" }
  end
end
