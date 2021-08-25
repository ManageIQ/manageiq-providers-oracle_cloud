FactoryBot.define do
  factory :ems_oracle_cloud, :class => "ManageIQ::Providers::OracleCloud::CloudManager", :parent => :ems_cloud do
    provider_region { "us-ashburn-1" }
  end

  factory :ems_oracle_cloud_with_vcr_authentication, :parent => :ems_oracle_cloud do
    uid_ems { Rails.application.secrets.oracle_cloud[:tenant_id] }

    after(:create) do |ems|
      user_id     = Rails.application.secrets.oracle_cloud[:user_id]
      private_key = Rails.application.secrets.oracle_cloud[:private_key]
      public_key  = Rails.application.secrets.oracle_cloud[:public_key]

      ems.authentications << FactoryBot.create(
        :authentication,
        :userid     => user_id,
        :auth_key   => private_key,
        :public_key => public_key
      )
    end
  end

  factory :ems_oracle_oke, :class => "ManageIQ::Providers::OracleCloud::ContainerManager", :parent => :ems_container do
    provider_region { "us-ashburn-1" }
  end

  factory :ems_oracle_oke_with_vcr_authentication, :parent => :ems_oracle_oke do
    realm { Rails.application.secrets.oracle_cloud[:tenant_id] }
    uid_ems { Rails.application.secrets.oracle_oke[:cluster_id] }

    after(:create) do |ems|
      user_id     = Rails.application.secrets.oracle_cloud[:user_id]
      private_key = Rails.application.secrets.oracle_cloud[:private_key]
      public_key  = Rails.application.secrets.oracle_cloud[:public_key]

      ems.default_endpoint.update!(
        :hostname          => Rails.application.secrets.oracle_oke[:hostname],
        :port              => Rails.application.secrets.oracle_oke[:port],
        :security_protocol => "ssl-without-validation"
      )

      ems.authentications << FactoryBot.create(
        :authentication,
        :authtype   => "bearer",
        :userid     => user_id,
        :auth_key   => private_key,
        :public_key => public_key
      )
    end
  end
end
