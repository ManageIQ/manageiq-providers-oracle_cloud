class ManageIQ::Providers::OracleCloud::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AuthKeyPair
  require_nested :Flavor
  # require_nested :Provision
  # require_nested :ProvisionWorkflow
  # require_nested :MetricsCapture
  # require_nested :MetricsCollectorWorker
  require_nested :RefreshParser
  require_nested :RefreshWorker
  require_nested :Refresher
  require_nested :Template
  require_nested :Vm

  include ManageIQ::Providers::OracleCloud::ManagerMixin

  supports :regions
  supports :provisioning

  def self.hostname_required?
    false
  end

  def self.ems_type
    @ems_type ||= "oracle_cloud".freeze
  end

  def self.description
    @description ||= "Oracle Cloud".freeze
  end

  def description
    ManageIQ::Providers::OracleCloud::Regions.find_by_name(provider_region)[:description]
  end

  validates :provider_region, :inclusion => {:in => ManageIQ::Providers::OracleCloud::Regions.names}

  def vm_start(vm, _options = {})
    vm.start
  rescue => err
    _log.error("vm=[#{vm.name}], error: #{err}")
  end

  def vm_stop(vm, _options = {})
    vm.stop
  rescue => err
    _log.error("vm=[#{vm.name}], error: #{err}")
  end

  def vm_destroy(vm, _options = {})
    vm.vm_destroy
  rescue => err
    _log.error("vm=[#{vm.name}], error: #{err}")
  end

  def vm_reboot_guest(vm, _options = {})
    vm.reboot_guest
  rescue => err
    _log.error("vm=[#{vm.name}], error: #{err}")
  end
end
