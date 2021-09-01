class ManageIQ::Providers::OracleCloud::ContainerManager::EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
  require_nested :Runner

  def self.settings_name
    :event_catcher_oracle_oke
  end
end
