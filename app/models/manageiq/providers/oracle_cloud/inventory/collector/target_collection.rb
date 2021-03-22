class ManageIQ::Providers::OracleCloud::Inventory::Collector::TargetCollection < ManageIQ::Providers::OracleCloud::Inventory::Collector
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def availability_domains
    []
  end

  def boot_volumes
    []
  end

  def boot_volume_attachments
    return [] if instances.empty?

    @boot_volume_attachments ||= begin
      instances.flat_map do |instance|
        compute_client.list_boot_volume_attachments(
          instance.availability_domain,
          instance.compartment_id,
          :instance_id => instance.id
        ).data
      end
    end
  end

  def compartments
    []
  end

  def images
    refs = references(:miq_templates)
    return [] if refs.blank?

    @images ||= refs.map { |ref| compute_client.get_image(ref).data }
  end

  def instances
    refs = references(:vms)
    return [] if refs.blank?

    @instances ||= refs.map { |ref| compute_client.get_instance(ref).data }
  end

  def shapes
    []
  end

  def subnets
    []
  end

  def vcns
    []
  end

  def vnics
    []
  end

  def vnic_attachments
    []
  end

  def volumes
    []
  end

  def volume_attachments
    return [] if instances.empty?

    @volume_attachments ||= begin
      instances.flat_map do |instance|
        compute_client.list_volume_attachments(
          instance.compartment_id,
          :instance_id => instance.id
        ).data
      end
    end
  end

  private

  def references(collection)
    target.manager_refs_by_association&.dig(collection, :ems_ref)&.to_a&.compact || []
  end

  def parse_targets!
    target.targets.each do |t|
      case t
      when Vm
        parse_vm_target!(t)
      end
    end
  end

  def parse_vm_target!(vm)
    add_simple_target!(:vms, vm.ems_ref)
  end

  def add_simple_target!(association, ems_ref)
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref})
  end
end
