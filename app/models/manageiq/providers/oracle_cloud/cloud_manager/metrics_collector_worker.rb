class ManageIQ::Providers::OracleCloud::CloudManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
  self.default_queue_name = "oracle"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for Oracle Cloud"
  end
end
