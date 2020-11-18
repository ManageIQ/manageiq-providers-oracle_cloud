class ManageIQ::Providers::OracleCloud::Inventory::Persister::CloudManager < ManageIQ::Providers::OracleCloud::Inventory::Persister
  include ManageIQ::Providers::OracleCloud::Inventory::Persister::Definitions::CloudCollections

  def initialize_inventory_collections
    initialize_cloud_inventory_collections
  end
end
