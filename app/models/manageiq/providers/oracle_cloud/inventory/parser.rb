class ManageIQ::Providers::OracleCloud::Inventory::Parser < ManageIQ::Providers::Inventory::Parser
  require_nested :CloudManager
  require_nested :NetworkManager

  def parse
    cloud_tenants
    flavors
    images
    instances
  end

  def cloud_tenants
    collector.compartments.each do |compartment|
      persister.cloud_tenants.build(
        :name        => compartment.name,
        :description => compartment.description,
        :ems_ref     => compartment.id,
        :enabled     => compartment.lifecycle_state == "ACTIVE",
        :parent      => persister.cloud_tenants.lazy_find(compartment.compartment_id)
      )
    end
  end

  def flavors
    collector.shapes.each do |shape|
      persister.flavors.build(
        :ems_ref => shape.shape,
        :name    => shape.shape,
        :cpus    => shape.ocpus,
        :memory  => shape.memory_in_gbs.gigabytes
      )
    end
  end

  def images
    collector.images.each do |image|
      persister_image = persister.miq_templates.build(
        :ems_ref         => image.id,
        :uid_ems         => image.id,
        :name            => image.display_name,
        :location        => "unknown",
        :raw_power_state => "never",
        :template        => true,
        :vendor          => "oracle",
        :ems_created_on  => image.time_created
      )

      persister.hardwares.build(
        :vm_or_template      => persister_image,
        :guest_os            => OperatingSystem.normalize_os_name(image.operating_system),
        :size_on_disk        => image.size_in_mbs&.megabytes,
        :virtualization_type => image.launch_mode,
        :root_device_type    => image.launch_options&.boot_volume_type
      )

      persister.operating_systems.build(
        :vm_or_template => persister_image,
        :product_name   => "#{image.operating_system} #{image.operating_system_version}"
      )
    end
  end

  def instances
    collector.instances.each do |instance|
      persister.vms.build(
        :ems_ref          => instance.id,
        :uid_ems          => instance.id,
        :name             => instance.display_name,
        :location         => instance.compartment_id,
        :vendor           => "oracle",
        :raw_power_state  => instance.lifecycle_state,
        :flavor           => persister.flavors.lazy_find(instance.shape),
        :genealogy_parent => persister.miq_templates.lazy_find(instance.image_id),
        :cloud_tenant     => persister.cloud_tenants.lazy_find(instance.compartment_id)
      )
    end
  end
end
