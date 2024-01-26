class ManageIQ::Providers::OracleCloud::ContainerManager::RefreshWorker < ManageIQ::Providers::BaseManager::RefreshWorker
  def self.settings_name
    :ems_refresh_worker_oracle_oke
  end
end
