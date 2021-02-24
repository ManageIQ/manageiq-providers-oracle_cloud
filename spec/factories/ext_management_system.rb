FactoryBot.define do
  factory :ems_oracle_cloud, :class => "ManageIQ::Providers::OracleCloud::CloudManager", :parent => :ems_cloud do
    provider_region { "us-ashburn-1" }
  end

  factory :ems_oracle_cloud_with_vcr_authentication, :parent => :ems_oracle_cloud do
    uid_ems { "ocid1.tenancy.oc1..aaaaaaaa" }

    after(:create) do |ems|
      # These are all bogus values but Rails Secrets won't work because the replaced
      # values don't pass the local sdk client validation.  E.g. ORACLE_CLOUD_USER_ID
      # fails the user id format validation.
      #
      # To re-record the cassette replace these values with real ones and add
      # config.define_cassette_placeholder("ocid1.user.oc1..aaaaaaaa") { "real value" }
      # to spec/spec_helper.rb
      user_id     = "ocid1.user.oc1..aaaaaaaa"
      private_key = <<~PRIVATE_KEY
        -----BEGIN RSA PRIVATE KEY-----
        MIIBOwIBAAJBAMfW33yRX0zpGhFx8kvQcpip1pHG0QJVpUp7ik4W9JLl0PWqSudF
        eXF0hFAc+Vx9R7ufpxMZ4lp+10WetdObAzsCAwEAAQJBAIw8R1y9DymDst1nHucB
        AkoLdR2bbXS78WBRTX77MOobynsP5gJehUI8hEOkbzYIJNBlSS/3aFAHBrd72diL
        ZPECIQDnr3y/pug4gNsoOeDWPGPxmLbd8cK9LS4KA0jeQ2PbfQIhANzPzNaHwZ5R
        aV/TnK00HpNJQBSo4S4Qbfc6JkZsD2cXAiEAiMI4s/R07S16sBMCGdPJ9wl7ICWe
        Gwb5PyXTNIe5AQ0CIC5mzJjYdmuamBY3Fdmf9jzlS74LryZK9ZDae2iZFLOJAiA6
        7KHzcqovm0lETCaEKSMWhKEcIfmz4qbAqxbx+DmAlQ==
        -----END RSA PRIVATE KEY-----
      PRIVATE_KEY
      public_key = <<~PUBLIC_KEY
        -----BEGIN PUBLIC KEY-----
        MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAMfW33yRX0zpGhFx8kvQcpip1pHG0QJV
        pUp7ik4W9JLl0PWqSudFeXF0hFAc+Vx9R7ufpxMZ4lp+10WetdObAzsCAwEAAQ==
        -----END PUBLIC KEY-----
      PUBLIC_KEY

      ems.authentications << FactoryBot.create(
        :authentication,
        :userid     => user_id,
        :auth_key   => private_key,
        :public_key => public_key
      )
    end
  end
end
