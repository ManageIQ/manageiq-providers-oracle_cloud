class ManageIQ::Providers::OracleCloud::Inventory::Collector::ContainerManager < ManageIQ::Providers::Kubernetes::Inventory::Collector::ContainerManager
  require_nested :WatchNotice

  private

  def kubernetes_connection
    manager.connect
  end
end
