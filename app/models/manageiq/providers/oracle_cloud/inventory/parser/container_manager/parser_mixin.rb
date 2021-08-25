module ManageIQ::Providers::OracleCloud::Inventory::Parser::ContainerManager::ParserMixin
  extend ActiveSupport::Concern

  def find_host_by_provider_id(provider_id)
    return if provider_id.blank?

    ManageIQ::Providers::OracleCloud::CloudManager::Vm.find_by(:uid_ems => provider_id)
  end
end
