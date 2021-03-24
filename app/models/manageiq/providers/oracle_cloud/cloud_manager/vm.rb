class ManageIQ::Providers::OracleCloud::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  def self.calculate_power_state(raw_power_state)
    case raw_power_state.downcase
    when /running/, /starting/
      "on"
    when /shutdown/, /stopping/
      "off"
    else
      "unknown"
    end
  end
end
