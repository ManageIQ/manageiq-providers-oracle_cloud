FactoryBot.define do
  factory :ems_oracle_cloud, :class => "ManageIQ::Providers::OracleCloud::CloudManager", :parent => :ems_cloud do
    provider_region { "us-ashburn-1" }
  end

  factory :ems_oracle_cloud_with_vcr_authentication, :parent => :ems_oracle_cloud do
    uid_ems { Rails.application.secrets.oracle_cloud[:tenant_id] }

    after(:create) do |ems|
      # These are all bogus values but Rails Secrets won't work because the replaced
      # values don't pass the local sdk client validation.  E.g. ORACLE_CLOUD_USER_ID
      # fails the user id format validation.
      #
      # To re-record the cassette replace these values with real ones and add
      # config.define_cassette_placeholder("ocid1.user.oc1..aaaaaaaa") { "real value" }
      # to spec/spec_helper.rb
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
end
