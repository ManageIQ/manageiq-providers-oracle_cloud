class ManageIQ::Providers::OracleCloud::CloudManager::Template < ManageIQ::Providers::CloudManager::Template
  def provider_object(connection = nil)
    connection ||= ext_management_system.connect(:service => "Core::ComputeClient")
    connection.get_image(ems_ref)
  end
end
