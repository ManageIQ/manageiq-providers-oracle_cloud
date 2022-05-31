class ManageIQ::Providers::OracleCloud::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AvailabilityZone
  require_nested :CloudDatabase
  require_nested :CloudTenant
  require_nested :CloudVolume
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Flavor
  require_nested :MetricsCapture
  require_nested :MetricsCollectorWorker
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :Template
  require_nested :Vm

  include ManageIQ::Providers::OracleCloud::OciConnectMixin

  supports :create
  supports :metrics
  supports :regions

  before_create :ensure_managers
  before_update :ensure_managers_zone_and_provider_region

  validates_inclusion_of :provider_region, :in => ->(_) { ManageIQ::Providers::OracleCloud::Regions.names }

  def ensure_network_manager
    build_network_manager(:type => 'ManageIQ::Providers::OracleCloud::NetworkManager') unless network_manager
  end

  def connect(options = {})
    auth_type = options.delete(:auth_type)

    authentication = authentication_best_fit(auth_type)
    config = self.class.raw_connect(
      uid_ems,
      authentication.userid,
      authentication.auth_key,
      authentication.public_key,
      provider_region
    )

    service = options.delete(:service)
    if service
      api_client_klass = "OCI::#{service}".safe_constantize
      raise ArgumentError, _("Invalid service") if api_client_klass.nil?

      api_client_klass.new(options.reverse_merge(:config => config, :proxy_settings => self.class.oci_proxy_settings))
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

  def self.hostname_required?
    false
  end

  def self.ems_type
    @ems_type ||= "oracle_cloud".freeze
  end

  def self.description
    @description ||= "Oracle Cloud".freeze
  end

  def self.params_for_create
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
          :id         => "uid_ems",
          :name       => "uid_ems",
          :label      => _("Tenant ID"),
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
              :id                     => 'authentications.default.valid',
              :name                   => 'authentications.default.valid',
              :skipSubmit             => true,
              :isRequired             => true,
              :validationDependencies => %w[type zone_id provider_region uid_ems],
              :fields                 => [
                {
                  :component  => "text-field",
                  :id         => "authentications.default.userid",
                  :name       => "authentications.default.userid",
                  :label      => _("User ID"),
                  :helperText => _("Should have privileged access, such as root or administrator."),
                  :isRequired => true,
                  :validate   => [{:type => "required"}]
                },
                {
                  :component      => "password-field",
                  :componentClass => 'textarea',
                  :rows           => 10,
                  :id             => "authentications.default.auth_key",
                  :name           => "authentications.default.auth_key",
                  :label          => _("Private Key"),
                  :type           => "password",
                  :isRequired     => true,
                  :validate       => [{:type => "required"}]
                },
                {
                  :component  => "textarea",
                  :rows       => 10,
                  :id         => "authentications.default.public_key",
                  :name       => "authentications.default.public_key",
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

  def self.verify_credentials(args)
    region, tenant = args.values_at("provider_region", "uid_ems")

    default_endpoint = args.dig("authentications", "default")
    user, private_key, public_key = default_endpoint&.values_at("userid", "auth_key", "public_key")

    private_key ||= find(args["id"]).authentication_token("default")

    config = raw_connect(tenant, user, private_key, public_key, region)
    identity_api = OCI::Identity::IdentityClient.new(:config => config, :proxy_settings => oci_proxy_settings)
    !!identity_api.get_user(user)
  end

  def self.raw_connect(tenant, user, private_key, public_key, region)
    oci_config(tenant, user, private_key, public_key, region)
  end

  def allow_targeted_refresh?
    true
  end
end
