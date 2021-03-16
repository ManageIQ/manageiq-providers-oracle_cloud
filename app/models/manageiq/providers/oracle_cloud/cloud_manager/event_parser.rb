class ManageIQ::Providers::OracleCloud::CloudManager::EventParser
  def self.event_to_hash(event, ems_id = nil)
    {
      :source => "OracleCloud"
    }
  end
end
