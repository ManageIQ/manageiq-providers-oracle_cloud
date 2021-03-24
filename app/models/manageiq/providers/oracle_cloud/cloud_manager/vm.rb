class ManageIQ::Providers::OracleCloud::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  supports_not :suspend
  supports :terminate do
    unsupported_reason_add(:terminate, unsupported_reason(:control)) unless supports?(:control)
  end
  supports :reboot_guest do
    unsupported_reason_add(:reboot_guest, unsupported_reason(:control)) unless supports?(:control)
    unsupported_reason_add(:reboot_guest, _("The VM is not powered on")) unless current_state == "on"
  end

  def provider_object(connection = nil)
    connection ||= ext_management_system.connect(:service => "Core::ComputeClient")
    connection.get_instance(ems_ref)
  end

  def raw_destroy
    raise "VM has no #{ui_lookup(:table => "ext_management_systems")}, unable to destroy VM" unless ext_management_system

    with_provider_connection(:service => "Core::ComputeClient") do |compute_client|
      compute_client.terminate_instance(ems_ref)
    end
    update!(:raw_power_state => "DELETED")
  end

  def raw_start
    instance_action("START")
  end

  def raw_stop
    instance_action("STOP")
  end

  def raw_reset
    instance_action("RESET")
  end

  def raw_shutdown_guest
    instance_action("SOFTSTOP")
  end

  def raw_reboot_guest
    instance_action("SOFTRESET")
  end

  def self.calculate_power_state(raw_power_state)
    case raw_power_state.downcase
    when /running/, /starting/
      "on"
    when /shutdown/, /stopping/, /terminating/, /terminated/
      "off"
    else
      "unknown"
    end
  end

  private

  def instance_action(action)
    response = with_provider_connection(:service => "Core::ComputeClient") do |compute_client|
      compute_client.instance_action(ems_ref, action)
    end

    update!(:raw_power_state => response.data.lifecycle_state)
  end
end
