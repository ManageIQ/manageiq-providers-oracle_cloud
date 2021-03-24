class ManageIQ::Providers::OracleCloud::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AvailabilityZone
  require_nested :CloudVolume
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Flavor
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :Template
  require_nested :Vm

  include ManageIQ::Providers::OracleCloud::ManagerMixin

  supports :regions

  before_create :ensure_managers
  before_update :ensure_managers_zone_and_provider_region

  def ensure_network_manager
    build_network_manager(:type => 'ManageIQ::Providers::OracleCloud::NetworkManager') unless network_manager
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
          :options      => provider_region_options
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

  private_class_method def self.provider_region_options
    ManageIQ::Providers::OracleCloud::Regions
      .all
      .sort_by { |r| r[:name].downcase }
      .map { |r| {:label => r[:name], :value => r[:name]} }
  end

  validates :provider_region, :inclusion => {:in => ManageIQ::Providers::OracleCloud::Regions.names}

  def allow_targeted_refresh?
    true
  end
end
