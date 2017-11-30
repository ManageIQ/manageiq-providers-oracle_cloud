class ManageIQ::Providers::OracleCloud::CloudManager::Provision < ::MiqProvisionCloud
  include_concern 'Cloning'
  include_concern 'Disk'
  include_concern 'StateMachine'
end
