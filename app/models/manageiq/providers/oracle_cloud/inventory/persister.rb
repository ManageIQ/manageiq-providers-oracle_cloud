class ManageIQ::Providers::OracleCloud::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  require_nested :CloudManager
  require_nested :NetworkManager

  def initialize_inventory_collections
    add_collection(cloud, :cloud_tenants) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.manager.id} )
    end
    add_collection(cloud, :flavors)
    add_collection(cloud, :hardwares)
    add_collection(cloud, :miq_templates) do |builder|
      builder.add_properties(:model_class => ::ManageIQ::Providers::OracleCloud::CloudManager::Template)
    end
    add_collection(cloud, :operating_systems)
    add_collection(cloud, :vms)
    add_collection(cloud, :vm_and_miq_template_ancestry)
  end

  private

  def cloud_manager
    manager.kind_of?(EmsCloud) ? manager : manager.parent_manager
  end

  def add_cloud_collection(name)
    add_collection(cloud, name) do |builder|
      add_properties(:parent => cloud_manager)
      yield builder if block_given?
    end
  end
end
