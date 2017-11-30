module ManageIQ::Providers::OracleCloud::ManagerMixin
  extend ActiveSupport::Concern

  def api
    ManageIQ::Providers::OracleCloud::Regions.find_by_name(provider_region)[:hostname]
  end

  def connect(options = {})
    self.class.raw_connect(authentication_userid(options[:auth_type]), authentication_password(options[:auth_type]), hostname, api)
  end

  def verify_credentials(_auth_type = nil, _options = {})
    begin
      connect
    rescue => err
      raise MiqException::MiqInvalidCredentialsError, err.message
    end

    true
  end

  module ClassMethods
    def raw_connect(user, password, domain, api)
      require 'fog/oraclecloud'

      config = {
        :provider           => "oraclecloud",
        :oracle_username    => user,
        :oracle_password    => MiqPassword.try_decrypt(password),
        :oracle_domain      => domain,
        :oracle_compute_api => api
      }

      begin
        connection = ::Fog::Compute.new(config)
      rescue => err
        raise MiqException::MiqInvalidCredentialsError, err.message
      end

      connection
    end
  end
end
