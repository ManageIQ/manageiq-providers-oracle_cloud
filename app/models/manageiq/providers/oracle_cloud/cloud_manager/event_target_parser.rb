class ManageIQ::Providers::OracleCloud::CloudManager::EventTargetParser
  attr_reader :ems_event

  # @param ems_event [EmsEvent] EmsEvent object
  def initialize(ems_event)
    @ems_event = ems_event
  end

  # Parses all targets that are present in the EmsEvent given in the initializer
  #
  # @return [Array] Array of InventoryRefresh::Target objects
  def parse
    target_collection = InventoryRefresh::TargetCollection.new(
      :manager => ems_event.ext_management_system,
      :event   => ems_event
    )

    raw_event = ems_event.full_data

    resource_id = raw_event.dig("data", "resourceId")
    association = if resource_id.start_with?("ocid1.instance")
                    :vms
                  elsif resource_id.start_with?("ocid1.image")
                    :miq_templates
                  end

    if resource_id && association
      target_collection.add_target(
        :association => association,
        :manager_ref => {:ems_ref => resource_id}
      )
    end

    target_collection.targets
  end
end
