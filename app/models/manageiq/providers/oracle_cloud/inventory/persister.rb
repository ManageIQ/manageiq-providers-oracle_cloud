class ManageIQ::Providers::OracleCloud::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  require_nested :CloudManager
  require_nested :NetworkManager

  def initialize_inventory_collections
    add_cloud_collection(:cloud_tenants) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.manager.id} )
    end
    add_cloud_collection(:flavors)
    add_cloud_collection(:hardwares)
    add_cloud_collection(:miq_templates) do |builder|
      builder.add_properties(:model_class => ::ManageIQ::Providers::OracleCloud::CloudManager::Template)
    end
    add_cloud_collection(:operating_systems)
    add_cloud_collection(:vms)
    add_cloud_collection(:vm_and_miq_template_ancestry)

    add_network_collection(:network_ports)
    add_network_collection(:cloud_subnets)
    add_network_collection(:cloud_networks)
  end

  private

  def cloud_manager
    manager.kind_of?(EmsCloud) ? manager : manager.parent_manager
  end

  def network_manager
    manager.kind_of?(EmsNetwork) ? manager : manager.network_manager
  end

  def add_cloud_collection(name)
    add_collection(cloud, name) do |builder|
      builder.add_properties(:parent => cloud_manager)
      yield builder if block_given?
    end
  end

  def add_network_collection(name)
    add_collection(network, name) do |builder|
      builder.add_properties(:parent => cloud_manager)
      yield builder if block_given?
    end
  end
end
