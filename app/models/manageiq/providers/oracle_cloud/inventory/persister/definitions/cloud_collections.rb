module ManageIQ::Providers::OracleCloud::Inventory::Persister::Definitions::CloudCollections
  extend ActiveSupport::Concern

  def initialize_cloud_inventory_collections
    add_collection(cloud, :flavors)
    add_collection(cloud, :hardwares)
    add_collection(cloud, :operating_systems)
    add_collection(cloud, :vms)
    add_collection(cloud, :miq_templates) do |builder|
      builder.add_properties(:model_class => ::ManageIQ::Providers::OracleCloud::CloudManager::Template)
    end
    add_collection(cloud, :vm_and_miq_template_ancestry)
  end
end
