class ManageIQ::Providers::OracleCloud::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :TargetCollection

  def availability_domains
    @availability_domains ||= compartments.flat_map do |compartment|
      identity_client.list_availability_domains(compartment.id).data
    end
  end

  def boot_volumes
    @boot_volumes ||= availability_domains.flat_map do |availability_domain|
      blockstorage_client.list_boot_volumes(availability_domain.name, availability_domain.compartment_id).data
    end
  end

  def boot_volume_attachments
    @boot_volume_attachments ||= availability_domains.flat_map do |availability_domain|
      compute_client.list_boot_volume_attachments(availability_domain.name, availability_domain.compartment_id).data
    end
  end

  def boot_volume_attachments_by_instance_id
    @boot_volume_attachments_by_instance_id ||= boot_volume_attachments.group_by(&:instance_id)
  end

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

  def volumes
    @volumes ||= compartments.flat_map do |compartment|
      blockstorage_client.list_volumes(compartment.id).data
    end
  end

  def volume_attachments
    @volume_attachments ||= compartments.flat_map do |compartment|
      compute_client.list_volume_attachments(compartment.id).data
    end
  end

  def volume_attachments_by_instance_id
    @volume_attachments_by_instance_id ||= volume_attachments.group_by(&:instance_id)
  end

  private

  def blockstorage_client
    @blockstorage_client ||= manager.connect(:service => "Core::BlockstorageClient")
  end

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
