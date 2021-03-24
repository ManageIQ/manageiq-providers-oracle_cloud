describe ManageIQ::Providers::OracleCloud::CloudManager::MetricsCapture do
  let(:ems) { FactoryBot.create(:ems_oracle_cloud_with_vcr_authentication) }
  let(:vm)  { FactoryBot.create(:vm_oracle, :ext_management_system => ems, :ems_ref => "ocid1.instance.oc1.iad.anuwcljtw3enqvycv47dx6ewcsmpjqzazpqxblsikzzkiw7ubhhgopqf3i3q") }

  describe "#perf_collect_metrics" do
    let(:start_time) { "2021-03-23T18:00:00.000Z".to_time(:utc) }
    let(:end_time)   { "2021-03-23T19:00:00.000Z".to_time(:utc) }

    it "collects metrics" do
      VCR.use_cassette(described_class.name.underscore) do
        vm.perf_capture_realtime(start_time, end_time)
      end

      vm.reload

      expect(vm.metrics.count).to eq(61)

      first_metric = vm.metrics.find_by(:timestamp => start_time)
      expect(first_metric.cpu_usage_rate_average).to be_within(0.001).of(1.787)
      expect(first_metric.mem_usage_absolute_average).to be_within(0.001).of(66.560)
      expect(first_metric.disk_usage_rate_average).to be_within(0.001).of(51_218.45)
    end
  end
end
