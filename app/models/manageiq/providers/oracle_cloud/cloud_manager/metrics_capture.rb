class ManageIQ::Providers::OracleCloud::CloudManager::MetricsCapture < ManageIQ::Providers::CloudManager::MetricsCapture
  delegate :ext_management_system, :to => :target

  VIM_STYLE_COUNTERS = {
    "cpu_usage_rate_average"     => {
      :counter_key           => "cpu_usage_rate_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 1,
      :rollup                => "average",
      :unit_key              => "percent",
      :capture_interval_name => "realtime",
    }.freeze,
    "disk_usage_rate_average"    => {
      :counter_key           => "disk_usage_rate_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 2,
      :rollup                => "average",
      :unit_key              => "kilobytespersecond",
      :capture_interval_name => "realtime",
    }.freeze,
    "net_usage_rate_average"     => {
      :counter_key           => "net_usage_rate_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 2,
      :rollup                => "average",
      :unit_key              => "kilobytespersecond",
      :capture_interval_name => "realtime",
    }.freeze,
    "mem_usage_absolute_average" => {
      :counter_key           => "mem_usage_absolute_average",
      :instance              => "",
      :capture_interval      => "20",
      :precision             => 1,
      :rollup                => "average",
      :unit_key              => "percent",
      :capture_interval_name => "realtime",
    }.freeze,
  }.freeze

  def perf_collect_metrics(_interval_name, start_time = nil, end_time = nil)
    require "oci/monitoring/monitoring"

    raise _("No EMS defined") if ext_management_system.nil?

    end_time ||= Time.now.utc
    start_time ||= end_time - 4.hours

    counters_by_mor = {target.ems_ref => VIM_STYLE_COUNTERS}
    counter_values_by_mor = {target.ems_ref => {}}

    cpu_utilization = metrics_query("CpuUtilization", start_time, end_time)

    memory_utilization = metrics_query("MemoryUtilization", start_time, end_time)

    disk_read_bytes  = metrics_query("DiskBytesRead", start_time, end_time)
    disk_write_bytes = metrics_query("DiskBytesWritten", start_time, end_time)
    disk_usage_kbps  = bytes_to_kpbs(sum_datasets(disk_read_bytes, disk_write_bytes))

    net_read_bytes  = metrics_query("NetworkBytesIn", start_time, end_time)
    net_write_bytes = metrics_query("NetworkBytesOut", start_time, end_time)
    net_usage_kbps  = bytes_to_kpbs(sum_datasets(net_read_bytes, net_write_bytes))

    store_datapoints!(cpu_utilization, "cpu_usage_rate_average", counter_values_by_mor[target.ems_ref])
    store_datapoints!(memory_utilization, "mem_usage_absolute_average", counter_values_by_mor[target.ems_ref])
    store_datapoints!(disk_usage_kbps, "disk_usage_rate_average", counter_values_by_mor[target.ems_ref])
    store_datapoints!(net_usage_kbps, "net_usage_rate_average", counter_values_by_mor[target.ems_ref])

    return counters_by_mor, counter_values_by_mor
  end

  def metrics_query_params(counter_name, start_time, end_time, interval, statistic)
    OCI::Monitoring::Models::SummarizeMetricsDataDetails.new(
      :namespace  => "oci_computeagent",
      :query      => "#{counter_name}[#{interval}]{resourceID=#{target.ems_ref}}.#{statistic}()",
      :start_time => start_time,
      :end_time   => end_time,
      :resolution => interval
    )
  end

  def metrics_query(counter_name, start_time, end_time, interval = "1m", statistic = "avg")
    monitoring_client = ext_management_system.connect(:service => "Monitoring::MonitoringClient")

    query_params = metrics_query_params(counter_name, start_time, end_time, interval, statistic)
    metrics_data = monitoring_client.summarize_metrics_data(compartment_id, query_params).flat_map do |response|
      response.data&.first&.aggregated_datapoints
    end

    parse_datapoints(metrics_data.compact)
  end

  def parse_datapoints(aggregated_datapoints)
    aggregated_datapoints
      .index_by { |datapoint| datapoint.timestamp&.to_s }
      .except(nil)
      .transform_values(&:value)
  end

  def store_datapoints!(datapoints, counter_key, counter_values_by_mor)
    datapoints.each do |timestamp, datapoint|
      counter_values_by_mor.store_path(timestamp, counter_key, datapoint)
    end
  end

  def sum_datasets(set1, set2)
    set1.merge(set2) { |_ts, val1, val2| val1 + val2 }
  end

  def bytes_to_kpbs(datapoints, interval = 1.minute)
    datapoints.transform_values { |value| value / 1.kilobyte / interval }
  end

  def compartment_id
    target.cloud_tenant&.ems_ref || ext_management_system.uid_ems
  end
end
