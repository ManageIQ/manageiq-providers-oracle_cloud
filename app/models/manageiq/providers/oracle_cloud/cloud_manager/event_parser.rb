class ManageIQ::Providers::OracleCloud::CloudManager::EventParser
  def self.parse_compute_api_event!(event, event_hash)
    resource_id = event.dig("data", "resourceId")
    if resource_id&.start_with?("ocid1.instance") || resource_id&.start_with?("ocid1.image")
      event_hash[:vm_uid_ems] = resource_id
      event_hash[:vm_ems_ref] = resource_id
      event_hash[:vm_name]    = event.dig("data", "resourceName")
    end
  end

  def self.event_to_hash(event, ems_id = nil)
    event_hash = {
      :ems_id     => ems_id,
      :source     => "ORACLE",
      :event_type => event["eventType"],
      :ems_ref    => event["eventID"],
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
