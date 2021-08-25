class ManageIQ::Providers::OracleCloud::Inventory::Parser::ContainerManager < ManageIQ::Providers::Kubernetes::Inventory::Parser::ContainerManager
  require_nested :WatchNotice

  include ParserMixin
end
