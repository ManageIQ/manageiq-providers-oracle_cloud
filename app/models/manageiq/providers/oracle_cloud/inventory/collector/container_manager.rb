class ManageIQ::Providers::OracleCloud::Inventory::Collector::ContainerManager < ManageIQ::Providers::Kubernetes::Inventory::Collector::ContainerManager
  private

  def kubernetes_connection
    manager.connect
  end
end
