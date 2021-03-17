class ManageIQ::Providers::OracleCloud::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :TargetCollection

  def initialize_inventory_collections
    add_cloud_collection(:availability_zones, :secondary_refs => {:by_name => %i(name)})
    add_cloud_collection(:cloud_tenants)
    add_cloud_collection(:cloud_volumes)
    add_cloud_collection(:disks)
    add_cloud_collection(:flavors)
    add_cloud_collection(:hardwares)
    add_cloud_collection(:miq_templates)
    add_cloud_collection(:operating_systems)
    add_cloud_collection(:vms)
    add_cloud_collection(:vm_and_miq_template_ancestry)

    add_network_collection(:network_ports)
    add_network_collection(:cloud_subnets)
    add_network_collection(:cloud_subnet_network_ports)
    add_network_collection(:cloud_networks)
  end
end
