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
    def verify_credentials(user, tenant, private_key, public_key, region)
      config = raw_connect(user, tenant, private_key, public_key, region)
      identity_api = OCI::Identity::IdentityClient.new(:config => config)
      !!identity_api.get_user(user)
    end

    def raw_connect(user, tenant, private_key, public_key, region)
      require "oci"

      public_key = public_key.split("\n").delete_if { |part| part.start_with?("-----") }.join("\n")
      fingerprint = Digest::MD5.hexdigest(Base64.decode64(public_key)).scan(/../).join(":")

      config = OCI::Config.new
      config.user        = user
      config.tenancy     = tenant
      config.key_content = private_key
      config.fingerprint = fingerprint
      config.region      = region
      config
    end
  end
end
