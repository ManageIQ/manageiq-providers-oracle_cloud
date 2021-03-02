module ManageIQ::Providers::OracleCloud::ManagerMixin
  extend ActiveSupport::Concern

  def api
    ManageIQ::Providers::OracleCloud::Regions.regions.dig(provider_region, :hostname)
  end

  def connect(options = {})
    authentication = authentication_best_fit(options[:auth_type])
    config = self.class.raw_connect(
      uid_ems,
      authentication.userid,
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
    def verify_credentials(args)
      region, tenant = args.values_at("provider_region", "uid_ems")

      default_endpoint = args.dig("authentications", "default")
      user, private_key, public_key = default_endpoint&.values_at("userid", "auth_key", "public_key")

      config = raw_connect(tenant, user, private_key, public_key, region)
      identity_api = OCI::Identity::IdentityClient.new(:config => config)
      !!identity_api.get_user(user)
    end

    def raw_connect(tenant, user, private_key, public_key, region)
      require "oci"

      # Strip out any "----- BEGIN/END PUBLIC KEY -----" lines
      public_key.gsub!(/-----(BEGIN|END) PUBLIC KEY-----/, "")
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
