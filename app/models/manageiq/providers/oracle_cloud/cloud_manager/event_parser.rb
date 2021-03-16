class ManageIQ::Providers::OracleCloud::CloudManager::EventParser
  def self.parse_compute_api_event!(event, event_hash)
    event_type = event["eventType"]
    if event_type.start_with?("com.oraclecloud.computeapi.instance")
      event_hash["vm_uid_ems"] = event.dig("data", "resourceId")
      event_hash["vm_ems_ref"] = event.dig("data", "resourceId")
      event_hash["vm_name"]    = event.dig("data", "resourceName")
    end
  end

  def self.event_to_hash(event, ems_id = nil)
    event_hash = {
      :event_type => event["eventType"],
      :source     => "ORACLE",
      :ems_ref    => event["eventID"],
      :ems_id     => ems_id,
      :timestamp  => event["eventTime"],
      :full_data  => event
    }

    event_source = event["source"]&.underscore
    return if event_source.nil?

    event_parser_method = "parse_#{event_source}_event!"
    send(event_parser_method, event, event_hash) if respond_to?(event_parser_method)

    event_hash
  end
end
