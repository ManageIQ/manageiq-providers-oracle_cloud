class ManageIQ::Providers::OracleCloud::Inventory::Persister::TargetCollection < ManageIQ::Providers::OracleCloud::Inventory::Persister
  def targeted?
    true
  end

  def strategy
    :local_db_find_missing_references
  end
end
