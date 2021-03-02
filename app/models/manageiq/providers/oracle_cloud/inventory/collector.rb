class ManageIQ::Providers::OracleCloud::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager

  def compartments
    @compartments ||= begin
      root_compartment = identity_client.get_compartment(identity_client.api_client.config.tenancy).data

      compartments = identity_client.list_compartments(root_compartment.id, :access_level => "ANY", :compartment_id_in_subtree => true).data
      compartments.unshift(root_compartment)
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

  def subnets
    @subnets ||= compartments.flat_map do |compartment|
      virtual_network_client.list_subnets(compartment.id).data
    end
  end

  def vcns
    @vcns ||= compartments.flat_map do |compartment|
      virtual_network_client.list_vcns(compartment.id).data
    end
  end

  def vnics
    # There doesn't appear to be a #list_vnics method so we have to get these
    # one-at-a-time.
    @vnics ||= vnic_attachments.map do |vnic_attachment|
      virtual_network_client.get_vnic(vnic_attachment.vnic_id).data
    end
  end

  def vnic_attachments
    @vnic_attachments ||= compartments.flat_map do |compartment|
      compute_client.list_vnic_attachments(compartment.id).data
    end
  end

  def vnic_attachments_by_vnic_id
    @vnic_attachments_by_vnic_id ||= vnic_attachments.index_by(&:vnic_id)
  end

  def vnic_attachments_by_instance_id
    @vnic_attachments_by_instance_id ||= vnic_attachments.group_by(&:instance_id)
  end

  private

  def compute_client
    @compute_client ||= manager.connect(:service => "Core::ComputeClient")
  end

  def identity_client
    @identity_client ||= manager.connect(:service => "Identity::IdentityClient")
  end

  def virtual_network_client
    @virtual_network_client ||= manager.connect(:service => "Core::VirtualNetworkClient")
  end
end
