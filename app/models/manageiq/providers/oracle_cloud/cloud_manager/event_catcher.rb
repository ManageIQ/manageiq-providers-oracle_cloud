class ManageIQ::Providers::OracleCloud::CloudManager::EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
  require_nested :Runner
  require_nested :Stream
end
