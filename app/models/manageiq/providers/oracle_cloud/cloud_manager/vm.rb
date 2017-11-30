class ManageIQ::Providers::OracleCloud::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  include_concern 'Operations'

  def provider_object(connection = nil)
    connection ||= ext_management_system.connect
    connection.instance(ems_ref)
  end

  def raw_start
    with_provider_object(&:start)
    update_attributes!(:raw_power_state => "on")
  end

  def raw_stop
    with_provider_object(&:stop)
    update_attributes!(:raw_power_state => "off")
  end

  def raw_pause
    with_provider_object(&:pause)
    update_attributes!(:raw_power_state => "paused")
  end

  def raw_suspend
    with_provider_object(&:suspend)
    update_attributes!(:raw_power_state => "suspended")
  end

  def self.calculate_power_state(raw_power_state)
    case raw_power_state.downcase
    when /running/, /starting/
      "on"
    when /stopped/, /stopping/
      "off"
    else
      "unknown"
    end
  end
end
