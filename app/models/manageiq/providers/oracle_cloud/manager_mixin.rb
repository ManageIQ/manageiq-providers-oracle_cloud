module ManageIQ::Providers::OracleCloud::ManagerMixin
  extend ActiveSupport::Concern

  def api
    ManageIQ::Providers::OracleCloud::Regions.find_by_name(provider_region)[:hostname]
  end

  def connect(options = {})
    authentication = authentication_best_fit(options[:auth_type])
    config = self.class.raw_connect(
      authentication.userid,
      authentication.service_account,
      authentication.auth_key,
      authentication.public_key,
      provider_region
    )

    if options[:service]
      api_client_klass = "OCI::#{options[:service]}".safe_constantize
      raise ArgumentError, _("Invalid service") if api_client_klass.nil?

      api_client_klass.new(:config => config)
    else
      config
    end
  end

  def verify_credentials(auth_type = nil, _options = {})
    begin
      connect(:service => "Identity::IdentityClient").get_user(authentication_userid(auth_type))
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

      # Strip out any "----- BEGIN/END PUBLIC KEY -----" lines
      public_key = public_key.split("\n").delete_if { |part| part.start_with?("-----") }.join("\n")
      # Build a key fingerprint e.g. aa:bb:cc:dd:ee...
      fingerprint = Digest::MD5.hexdigest(Base64.decode64(public_key)).scan(/../).join(":")

      config = OCI::Config.new

      config.user        = user
      config.tenancy     = tenant
      config.key_content = ManageIQ::Password.try_decrypt(private_key)
      config.fingerprint = fingerprint
      config.region      = region

      config
    end
  end
end
