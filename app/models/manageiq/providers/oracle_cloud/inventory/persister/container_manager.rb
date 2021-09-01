class ManageIQ::Providers::OracleCloud::Inventory::Persister::ContainerManager < ManageIQ::Providers::Kubernetes::Inventory::Persister::ContainerManager
  require_nested :WatchNotice
end
