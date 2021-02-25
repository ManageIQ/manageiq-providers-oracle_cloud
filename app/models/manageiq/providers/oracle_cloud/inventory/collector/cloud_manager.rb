class ManageIQ::Providers::OracleCloud::Inventory::Collector::CloudManager < ManageIQ::Providers::OracleCloud::Inventory::Collector
  def compartments
    @compartments ||= begin
      root_compartment = identity_client.get_compartment(identity_client.api_client.config.tenancy).data

      compartments = [root_compartment]
      compartments += identity_client.list_compartments(root_compartment.id, :access_level => "ANY", :compartment_id_in_subtree => true).data

      compartments
    end
  end

  def images
    @images ||= compartments.flat_map do |compartment|
      compute_client.list_images(compartment.id).data
    end
  end

  def instances
    @instances ||= compartments.flat_map do |compartment|
      compute_client.list_instances(compartment.id).data
    end
  end

  def shapes
    @shapes ||= compartments.flat_map do |compartment|
      compute_client.list_shapes(compartment.id).data
    end
  end

  private

  def compute_client
    @compute_client ||= manager.connect(:service => "Core::ComputeClient")
  end

  def identity_client
    @identity_client ||= manager.connect(:service => "Identity::IdentityClient")
  end
end
