ManageIQ::Providers::Kubernetes::ContainerManager.include(ActsAsStiLeafClass)

class ManageIQ::Providers::OracleCloud::ContainerManager < ManageIQ::Providers::Kubernetes::ContainerManager
  require_nested :Container
  require_nested :ContainerGroup
  require_nested :ContainerNode
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Refresher
  require_nested :RefreshWorker

  include ManageIQ::Providers::OracleCloud::OciConnectMixin

  validates :provider_region, :inclusion => {:in => ManageIQ::Providers::OracleCloud::Regions.names}

  def connect_options(options = {})
    options.merge(
      :hostname    => options[:hostname] || address,
      :port        => options[:port] || port,
      :bearer      => bearer_token(options[:auth_type]),
      :http_proxy  => self.options ? self.options.fetch_path(:proxy_settings, :http_proxy) : nil,
      :ssl_options => options[:ssl_options] || {
        :verify_ssl => verify_ssl_mode,
        :cert_store => ssl_cert_store
      }
    )
  end

  def bearer_token(auth_type)
    authentication = authentication_best_fit(auth_type || "bearer")
    self.class.bearer_token(realm, authentication.userid, authentication.auth_key, authentication.public_key, provider_region, uid_ems)
  end

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
      6443
    end

    def params_for_create
      {
        :fields => [
          {
            :component    => "select",
            :id           => "provider_region",
            :name         => "provider_region",
            :label        => _("Region"),
            :isRequired   => true,
            :validate     => [{:type => "required"}],
            :includeEmpty => true,
            :options      => ManageIQ::Providers::OracleCloud::Regions.regions_for_options
          },
          {
            :component  => "text-field",
            :id         => "realm",
            :name       => "realm",
            :label      => _("Tenant ID"),
            :isRequired => true,
            :validate   => [{:type => "required"}]
          },
          {
            :component  => "text-field",
            :id         => "uid_ems",
            :name       => "uid_ems",
            :label      => _("Cluster ID"),
            :isRequired => true,
            :validate   => [{:type => "required"}]
          },
          {
            :component => 'sub-form',
            :name      => 'endpoints-subform',
            :id        => 'endpoints-subform',
            :title     => _("Endpoints"),
            :fields    => [
              {
                :component              => 'validate-provider-credentials',
                :id                     => 'authentications.bearer.valid',
                :name                   => 'authentications.bearer.valid',
                :skipSubmit             => true,
                :isRequired             => true,
                :validationDependencies => %w[type zone_id provider_region realm uid_ems],
                :fields                 => [
                  {
                    :component    => "select",
                    :id           => "endpoints.default.security_protocol",
                    :name         => "endpoints.default.security_protocol",
                    :label        => _("Security Protocol"),
                    :isRequired   => true,
                    :validate     => [{:type => "required"}],
                    :initialValue => 'ssl-with-validation',
                    :options      => [
                      {
                        :label => _("SSL"),
                        :value => "ssl-with-validation"
                      },
                      {
                        :label => _("SSL trusting custom CA"),
                        :value => "ssl-with-validation-custom-ca"
                      },
                      {
                        :label => _("SSL without validation"),
                        :value => "ssl-without-validation",
                      },
                    ]
                  },
                  {
                    :component  => "text-field",
                    :id         => "endpoints.default.hostname",
                    :name       => "endpoints.default.hostname",
                    :label      => _("Hostname (or IPv4 or IPv6 address)"),
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                  },
                  {
                    :component    => "text-field",
                    :id           => "endpoints.default.port",
                    :name         => "endpoints.default.port",
                    :label        => _("API Port"),
                    :type         => "number",
                    :initialValue => default_port,
                    :isRequired   => true,
                    :validate     => [{:type => "required"}],
                  },
                  {
                    :component  => "textarea",
                    :id         => "endpoints.default.certificate_authority",
                    :name       => "endpoints.default.certificate_authority",
                    :label      => _("Trusted CA Certificates"),
                    :rows       => 10,
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                    :condition  => {
                      :when => 'endpoints.default.security_protocol',
                      :is   => 'ssl-with-validation-custom-ca',
                    },
                  },
                  {
                    :component  => "text-field",
                    :id         => "authentications.bearer.userid",
                    :name       => "authentications.bearer.userid",
                    :label      => _("User ID"),
                    :helperText => _("Should have privileged access, such as root or administrator."),
                    :isRequired => true,
                    :validate   => [{:type => "required"}]
                  },
                  {
                    :component      => "password-field",
                    :componentClass => 'textarea',
                    :rows           => 10,
                    :id             => "authentications.bearer.auth_key",
                    :name           => "authentications.bearer.auth_key",
                    :label          => _("Private Key"),
                    :type           => "password",
                    :isRequired     => true,
                    :validate       => [{:type => "required"}]
                  },
                  {
                    :component  => "textarea",
                    :rows       => 10,
                    :id         => "authentications.bearer.public_key",
                    :name       => "authentications.bearer.public_key",
                    :label      => "Public Key",
                    :isRequired => true,
                    :validate   => [{:type => "required"}]
                  }
                ],
              },
            ]
          }
        ]
      }
    end

    def verify_credentials(args)
      region, tenant, cluster_id = args.values_at("provider_region", "realm", "uid_ems")

      default_endpoint = args.dig("endpoints", "default")
      hostname, port = default_endpoint&.values_at("hostname", "port")

      default_authentication = args.dig("authentications", "bearer")
      user, private_key, public_key = default_authentication&.values_at("userid", "auth_key", "public_key")
      private_key ||= find(args["id"]).authentication_token("default")

      bearer = bearer_token(tenant, user, private_key, public_key, region, cluster_id)

      options = {
        :bearer      => bearer,
        :ssl_options => {
          :verify_ssl => OpenSSL::SSL::VERIFY_NONE
        }
      }

      !!raw_connect(hostname, port, options)
    end

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
  end
end
