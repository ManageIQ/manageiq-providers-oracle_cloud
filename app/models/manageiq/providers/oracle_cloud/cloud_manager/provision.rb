class ManageIQ::Providers::OracleCloud::CloudManager::Provision < ManageIQ::Providers::CloudManager::Provision
  def do_clone_task_check(instance_id)
    source.with_provider_connection(:service => "Core::ComputeClient") do |compute_client|
      instance = compute_client.get_instance(instance_id).data
      case instance.lifecycle_state
      when OCI::Core::Models::Instance::LIFECYCLE_STATE_RUNNING
        true
      when OCI::Core::Models::Instance::LIFECYCLE_STATE_TERMINATED,
           OCI::Core::Models::Instance::LIFECYCLE_STATE_TERMINATING
        raise _("Instance clone failed")
      else
        return false, "Provisioning"
      end
    end
  end

  def prepare_for_clone_task
    validate_dest_name

    {
      :availability_domain => dest_availability_zone.name,
      :compartment_id      => cloud_tenant.ems_ref,
      :display_name        => dest_name,
      :image_id            => source.ems_ref,
      :shape               => instance_type.ems_ref,
      :subnet_id           => cloud_subnet.ems_ref,
      :metadata            => {
        "ssh_authorized_keys" => ssh_public_key
      }
    }
  end

  def log_clone_options(clone_options)
    _log.info("Provisioning [#{source.name}] to [#{dest_name}]")
    _log.info("Source Template:     [#{options[:src_vm_id].last}]")
    _log.info("Availability Domain: [#{clone_options[:availability_domain].inspect}]")
    _log.info("Compartment:         [#{clone_options[:compartment_id].inspect}]")
    _log.info("Shape:               [#{clone_options[:shape].inspect}]")
    _log.info("Cloud Subnet:        [#{clone_options[:subnet_id].inspect}]")

    dump_obj(clone_options, "#{_log.prefix} Clone Options: ", $log, :info)
    dump_obj(options, "#{_log.prefix} Prov Options:  ", $log, :info, :protected => {:path => workflow_class.encrypted_options_field_regs})
  end

  def start_clone(clone_options)
    source.with_provider_connection(:service => "Core::ComputeClient") do |compute_client|
      response = compute_client.launch_instance(
        OCI::Core::Models::LaunchInstanceDetails.new(clone_options)
      )

      response.data.id
    end
  end

  private

  def cloud_tenant
    @cloud_tenant ||= CloudTenant.find_by(:id => get_option(:cloud_tenant))
  end

  def ssh_public_key
    @ssh_public_key ||= get_option(:ssh_public_key)
  end
end
