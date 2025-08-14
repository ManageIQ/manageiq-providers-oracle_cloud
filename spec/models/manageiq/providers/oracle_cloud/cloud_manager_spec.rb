describe ManageIQ::Providers::OracleCloud::CloudManager do
  it ".verify_credentials" do
    with_vcr do
      expect(
        described_class.verify_credentials(
          "provider_region" => "us-ashburn-1",
          "uid_ems"         => VcrSecrets.oracle_cloud.tenant_id,
          "authentications" => {
            "default" => {
              "userid"     => VcrSecrets.oracle_cloud.user_id,
              "auth_key"   => VcrSecrets.oracle_cloud.private_key,
              "public_key" => VcrSecrets.oracle_cloud.public_key
            }
          }
        )
      ).to be_truthy
    end
  end

  def with_vcr(&block)
    VCR.use_cassette(described_class.name.underscore, &block)
  end
end
