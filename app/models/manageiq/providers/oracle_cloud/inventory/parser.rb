class ManageIQ::Providers::OracleCloud::Inventory::Parser < ManageIQ::Providers::Inventory::Parser
  require_nested :ContainerManager
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :TargetCollection

  def parse
    availability_domains
    boot_volumes
    cloud_tenants
    databases
    flavors
    images
    instances
    subnets
    vnics
    virtual_cloud_networks
    volumes
  end

  def availability_domains
    collector.availability_domains.each do |availability_domain|
      persister.availability_zones.build(
        :ems_ref => availability_domain.id,
        :name    => availability_domain.name
      )
    end
  end

  def boot_volumes
    collector.boot_volumes.each do |boot_volume|
      persister.cloud_volumes.build(
        :ems_ref           => boot_volume.id,
        :name              => boot_volume.display_name,
        :size              => boot_volume.size_in_mbs.megabytes,
        :status            => boot_volume.lifecycle_state,
        :availability_zone => persister.availability_zones.lazy_find({:name => boot_volume.availability_domain}, {:ref => :by_name}),
        :cloud_tenant      => persister.cloud_tenants.lazy_find(boot_volume.compartment_id)
      )
    end
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

  def databases
    collector.oracle_databases.each do |database|
      persister.cloud_databases.build(
        :ems_ref      => database.id,
        :name         => database.db_name,
        :cloud_tenant => persister.cloud_tenants.lazy_find(database.compartment_id),
        :db_engine    => "Oracle Database #{database.db_version}",
        :used_storage => database.data_storage_size_in_gbs&.gigabytes
      )
    end

    collector.mysql_databases.each do |database|
      persister.cloud_databases.build(
        :ems_ref      => database.id,
        :name         => database.display_name,
        :cloud_tenant => persister.cloud_tenants.lazy_find(database.compartment_id),
        :db_engine    => "MySQL #{database.mysql_version}"
      )
    end
  end

  def flavors
    collector.shapes.each do |shape|
      persister.flavors.build(
        :ems_ref         => shape.shape,
        :name            => shape.shape,
        :cpu_total_cores => shape.ocpus,
        :memory          => shape.memory_in_gbs.gigabytes
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
      vm = persister.vms.build(
        :ems_ref           => instance.id,
        :uid_ems           => instance.id,
        :name              => instance.display_name,
        :location          => instance.compartment_id,
        :vendor            => "oracle",
        :raw_power_state   => instance.lifecycle_state,
        :flavor            => persister.flavors.lazy_find(instance.shape),
        :genealogy_parent  => persister.miq_templates.lazy_find(instance.image_id),
        :cloud_tenant      => persister.cloud_tenants.lazy_find(instance.compartment_id),
        :availability_zone => persister.availability_zones.lazy_find({:name => instance.availability_domain}, {:ref => :by_name})
      )

      hardware = persister.hardwares.build(
        :vm_or_template => vm
      )

      boot_volumes = Array(collector.boot_volume_attachments_by_instance_id[instance.id])
      boot_volumes.each do |attachment|
        persister.disks.build(
          :hardware    => hardware,
          :device_name => attachment.display_name,
          :backing     => persister.cloud_volumes.lazy_find(attachment.boot_volume_id)
        )
      end

      volumes = Array(collector.volume_attachments_by_instance_id[instance.id])
      volumes.each do |attachment|
        persister.disks.build(
          :hardware    => hardware,
          :device_name => attachment.display_name,
          :backing     => persister.cloud_volumes.lazy_find(attachment.volume_id)
        )
      end
    end
  end

  def subnets
    collector.subnets.each do |subnet|
      persister.cloud_subnets.build(
        :ems_ref       => subnet.id,
        :name          => subnet.display_name,
        :cidr          => subnet.cidr_block,
        :gateway       => subnet.virtual_router_ip,
        :status        => subnet.lifecycle_state,
        :cloud_network => persister.cloud_networks.lazy_find(subnet.vcn_id),
        :cloud_tenant  => persister.cloud_tenants.lazy_find(subnet.compartment_id)
      )
    end
  end

  def virtual_cloud_networks
    collector.vcns.each do |vcn|
      persister.cloud_networks.build(
        :ems_ref      => vcn.id,
        :name         => vcn.display_name,
        :cidr         => vcn.cidr_block,
        :status       => vcn.lifecycle_state,
        :enabled      => vcn.lifecycle_state == "AVAILABLE",
        :cloud_tenant => persister.cloud_tenants.lazy_find(vcn.compartment_id)
      )
    end
  end

  def vnics
    collector.vnics.each do |vnic|
      vnic_attachment = collector.vnic_attachments_by_vnic_id[vnic.id]
      next if vnic_attachment.nil?

      instance_id = vnic_attachment.instance_id

      network_port = persister.network_ports.build(
        :ems_ref      => vnic.id,
        :name         => vnic.display_name,
        :status       => vnic.lifecycle_state,
        :mac_address  => vnic.mac_address,
        :device       => persister.vms.lazy_find(instance_id),
        :cloud_tenant => persister.cloud_tenants.lazy_find(vnic.compartment_id)
      )

      if vnic.private_ip
        persister.cloud_subnet_network_ports.build(
          :address      => vnic.private_ip,
          :cloud_subnet => persister.cloud_subnets.lazy_find(vnic.subnet_id),
          :network_port => network_port
        )
      end

      if vnic.public_ip
        persister.cloud_subnet_network_ports.build(
          :address      => vnic.public_ip,
          :cloud_subnet => persister.cloud_subnets.lazy_find(vnic.subnet_id),
          :network_port => network_port
        )
      end
    end
  end

  def volumes
    collector.volumes.each do |volume|
      persister.cloud_volumes.build(
        :ems_ref           => volume.id,
        :name              => volume.display_name,
        :size              => volume.size_in_mbs.megabytes,
        :status            => volume.lifecycle_state,
        :availability_zone => persister.availability_zones.lazy_find({:name => volume.availability_domain}, {:ref => :by_name}),
        :cloud_tenant      => persister.cloud_tenants.lazy_find(volume.compartment_id)
      )
    end
  end
end
