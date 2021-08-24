ManageIQ::Providers::Kubernetes::ContainerManager.include(ActsAsStiLeafClass)

class ManageIQ::Providers::OracleCloud::ContainerManager < ManageIQ::Providers::Kubernetes::ContainerManager
  require_nested :Container
  require_nested :ContainerGroup
  require_nested :ContainerNode
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Refresher
  require_nested :RefreshWorker

  class << self
    def ems_type
      @ems_type ||= "oke".freeze
    end

    def description
      @description ||= "Oracle Kubernetes Engine".freeze
    end

    def display_name(number = 1)
      n_('Container Provider (Oracle)', 'Container Providers (Oracle)', number)
    end

    def default_port
      443
    end

    def params_for_create
      {
      }
    end

    def verify_credentials(args)
      region, tenant, cluster_id = args.values_at("provider_region", "realm", "uid_ems")

      default_endpoint = args.dig("endpoints", "default")
      hostname, port = default_endpoint&.values_at("hostname", "port")

      default_authentication = args.dig("authentications", "default")
      user, private_key, public_key = default_authentication&.values_at("userid", "auth_key", "public_key")
      private_key ||= find(args["id"]).authentication_token("default")

      bearer = bearer_token(tenant, user, private_key, public_key, region, cluster_id)

      options = {
        :bearer => bearer,
        :ssl_options => {
          :verify_ssl => OpenSSL::SSL::VERIFY_NONE
        }
      }

      !!raw_connect(hostname, port, options)
    end

    private

    def bearer_token(tenant, user, private_key, public_key, region, cluster_id)
      config                  = oci_config(tenant, user, private_key, public_key, region)
      container_engine_client = OCI::ContainerEngine::ContainerEngineClient.new(:config => config)

      # Prepare a signed request
      signer = container_engine_client.api_client.instance_variable_get(:@signer)

      url = URI::HTTPS.build(
        :host => "containerengine.#{region}.oraclecloud.com",
        :path => "/cluster_request/#{cluster_id}"
      )

      params = {}
      signer.sign(:GET, url, params, nil)

      url.query = params.to_query

      Base64.urlsafe_encode64(url.to_s)
    end

    def oci_config(tenant, user, private_key, public_key, region)
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
