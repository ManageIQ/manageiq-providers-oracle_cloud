class ManageIQ::Providers::OracleCloud::NetworkManager < ManageIQ::Providers::NetworkManager
  require_nested :CloudNetwork
  require_nested :NetworkPort
  require_nested :Refresher

  # Auth and endpoints delegations, editing of this type of manager must be disabled
  delegate :authentication_check,
           :authentication_status,
           :authentication_status_ok?,
           :authentications,
           :authentication_for_summary,
           :zone,
           :connect,
           :verify_credentials,
           :with_provider_connection,
           :address,
           :ip_address,
           :hostname,
           :default_endpoint,
           :endpoints,
           :to        => :parent_manager,
           :allow_nil => true

  def self.ems_type
    @ems_type ||= "oracle_cloud_network".freeze
  end

  def self.description
    @description ||= "Oracle Cloud Network".freeze
  end

  def description
    @description ||= "Oracle Cloud Network".freeze
  end

  def self.hostname_required?
    false
  end
end
