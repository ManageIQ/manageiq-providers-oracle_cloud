class ManageIQ::Providers::OracleCloud::Inventory < ManageIQ::Providers::Inventory
  require_nested :Collector
  require_nested :Parser
  require_nested :Persister

  def self.default_manager_name
    "CloudManager"
  end

  def self.parser_classes_for(ems, target)
    case target
    when InventoryRefresh::TargetCollection
      [ManageIQ::Providers::OracleCloud::Inventory::Parser]
    else
      super
    end
  end
end
