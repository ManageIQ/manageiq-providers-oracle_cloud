class ManageIQ::Providers::OracleCloud::CloudManager::Template < ManageIQ::Providers::CloudManager::Template
  supports :provisioning do
    if ext_management_system
      ext_management_system.unsupported_reason(:provisioning)
    else
      _('not connected to ems')
    end
  end

  def provider_object(connection = nil)
    connection ||= ext_management_system.connect(:service => "Core::ComputeClient")
    connection.get_image(ems_ref)
  end
end
