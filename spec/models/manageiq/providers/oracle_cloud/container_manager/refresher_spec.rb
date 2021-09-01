describe ManageIQ::Providers::OracleCloud::ContainerManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:oke)
  end

  let(:zone) { EvmSpecHelper.create_guid_miq_server_zone.last }
  let!(:ems) { FactoryBot.create(:ems_oracle_oke_with_vcr_authentication, :zone => zone) }

  it "will perform a full refresh" do
    2.times do
      VCR.use_cassette(described_class.name.underscore) { EmsRefresh.refresh(ems) }

      ems.reload

      assert_table_counts
    end
  end

  def assert_table_counts
    expect(ems.container_projects.count).to         eq(4)
    expect(ems.container_nodes.count).to            eq(3)
    expect(ems.container_services.count).to         eq(2)
    expect(ems.container_groups.count).to           eq(16)
    expect(ems.containers.count).to                 eq(16)
    expect(ems.container_images.count).to           eq(6)
    expect(ems.container_image_registries.count).to eq(1)
  end
end
