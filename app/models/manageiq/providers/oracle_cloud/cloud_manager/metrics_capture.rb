class ManageIQ::Providers::OracleCloud::CloudManager::MetricsCapture < ManageIQ::Providers::CloudManager::MetricsCapture
  delegate :ext_management_system, :to => :target

  def perf_collect_metrics(inverval_name, start_time = nil, end_time = nil)
    raise _("No EMS defined") if ext_management_system.nil?

    end_time ||= Time.now.utc
    start_time ||= end_time - 4.hours

    ext_management_system.with_provider_connection(:service => "Monitoring::MonitoringClient") do |monitoring_client|
      summarize_metrics_data_details = OCI::Monitoring::Models::SummarizeMetricsDataDetails.new(:namespace => "oci_computeagent", :query => "CpuUtilization[1m].sum()")

      metrics = monitoring_client.summarize_metrics_data(ext_management_system.uid_ems, summarize_metrics_data_details).data
    end
  end
end
