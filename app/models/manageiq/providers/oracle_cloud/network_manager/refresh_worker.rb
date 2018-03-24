class ManageIQ::Providers::OracleCloud::NetworkManager::RefreshWorker < ::MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    ManageIQ::Providers::OracleCloud::NetworkManager
  end

  def self.settings_name
    :ems_refresh_worker_oracle_cloud_network
  end
end
