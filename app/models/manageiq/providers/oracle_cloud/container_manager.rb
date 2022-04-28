ManageIQ::Providers::Kubernetes::ContainerManager.include(ActsAsStiLeafClass)

class ManageIQ::Providers::OracleCloud::ContainerManager < ManageIQ::Providers::Kubernetes::ContainerManager
  require_nested :Container
  require_nested :ContainerGroup
  require_nested :ContainerImage
  require_nested :ContainerNode
  require_nested :ContainerTemplate
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :ServiceInstance
  require_nested :ServiceOffering
  require_nested :ServiceParametersSet

  include ManageIQ::Providers::OracleCloud::OciConnectMixin

  validates_inclusion_of :provider_region, :in => ->(_) { ManageIQ::Providers::OracleCloud::Regions.names }

  supports :create

  def connect_options(options = {})
    authentication = authentication_best_fit(options.fetch(:auth_type, "bearer"))

    super.merge(
      :tenant      => realm,
      :user        => authentication.userid,
      :private_key => authentication.auth_key,
      :public_key  => authentication.public_key,
      :region      => provider_region,
      :cluster_id  => uid_ems
    )
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

    def kubernetes_auth_options(options)
      {
        :bearer_token => bearer_token(*options.values_at(:tenant, :user, :private_key, :public_key, :region, :cluster_id))
      }
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
      hostname, port, security_protocol, certificate_authority = default_endpoint&.values_at("hostname", "port", "security_protocol", "certificate_authority")

      default_authentication = args.dig("authentications", "bearer")
      user, private_key, public_key = default_authentication&.values_at("userid", "auth_key", "public_key")
      private_key ||= find(args["id"]).authentication_token("default")

      options = {
        :tenant      => tenant,
        :user        => user,
        :private_key => private_key,
        :public_key  => public_key,
        :region      => region,
        :cluster_id  => cluster_id,
        :ssl_options => {
          :verify_ssl            => security_protocol == "ssl-without-validation" ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER,
          :certificate_authority => certificate_authority
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
