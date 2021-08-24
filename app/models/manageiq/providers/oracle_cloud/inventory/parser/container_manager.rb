class ManageIQ::Providers::OracleCloud::Inventory::Parser::ContainerManager < ManageIQ::Providers::Kubernetes::Inventory::Parser::ContainerManager
  require_nested :WatchNotice

  def find_host_by_provider_id(_provider_id)
    nil
  end
end
