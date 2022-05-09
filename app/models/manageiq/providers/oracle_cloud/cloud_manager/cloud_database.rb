class ManageIQ::Providers::OracleCloud::CloudManager::CloudDatabase < ::CloudDatabase
  supports :create

  def self.params_for_create(ems)
    {
      :fields => [
        {
          :component => 'text-field',
          :id        => 'name',
          :name      => 'name',
          :label     => _('Cloud Database Name'),
        },
        {
          :component    => 'select',
          :name         => 'database',
          :id           => 'database',
          :label        => _('Database Type'),
          :includeEmpty => true,
          :isRequired   => true,
          :options      => ['oracle', 'mysql'].map do |db|
            {
              :label => db,
              :value => db
            }
          end,
        },
        {
          :component    => 'select',
          :name         => 'availability_domain',
          :id           => 'availability_domain',
          :label        => _('Availability Domain'),
          :includeEmpty => true,
          :isRequired   => true,
          :options      => ems.availability_zones.map do |az|
            {
              :label => az.name,
              :value => az.id.to_s
            }
          end,
        },
        {
          :component  => 'text-field',
          :id         => 'compartment_id',
          :name       => 'compartment_id',
          :label      => _('Compartment ID'),
          :isRequired => true,
        },
        {
          :component  => 'text-field',
          :id         => 'username',
          :name       => 'username',
          :label      => _('Admin Username'),
          :isRequired => true,
          :condition  => {
            :when => 'database',
            :is   => 'mysql',
          },
        },
        {
          :component  => 'text-field',
          :id         => 'password',
          :name       => 'password',
          :label      => _('Admin Password'),
          :isRequired => true,
        },
        {
          :component  => 'text-field',
          :id         => 'shape_name',
          :name       => 'shape_name',
          :label      => _('Database Shape Name'),
          :isRequired => true,
          :condition  => {
            :when => 'database',
            :is   => 'mysql',
          },
        },
        {
          :component    => 'select',
          :name         => 'subnet',
          :id           => 'subnet',
          :label        => _('Cloud Subnet'),
          :includeEmpty => true,
          :isRequired   => true,
          :condition    => {
            :when => 'database',
            :is   => 'mysql',
          },
          :options      => ems.cloud_subnets.map do |cs|
            {
              :label => cs.name,
              :value => cs.id.to_s
            }
          end
        },
        {
          :component  => 'text-field',
          :name       => 'cpu_cores',
          :id         => 'cpu_cores',
          :label      => _('CPU Cores'),
          :type       => 'number',
          :step       => 1,
          :isRequired => true,
          :condition  => {
            :when => 'database',
            :is   => 'oracle',
          },
        },
        {
          :component  => 'text-field',
          :name       => 'storage',
          :id         => 'storage',
          :label      => _('Storage Size (in Terabytes)'),
          :type       => 'number',
          :step       => 1,
          :isRequired => true,
          :condition  => {
            :when => 'database',
            :is   => 'oracle',
          },
        },
      ],
    }
  end

  def self.raw_create_cloud_database(ext_management_system, options)
    options[:database] == 'oracle' ? create_oracle_database(ext_management_system, options) : create_mysql_database(ext_management_system, options)
  rescue => err
    _log.error("cloud database=[#{options[:name]}], error: #{err}")
    raise
  end

  def self.create_oracle_database(ext_management_system, options)
    require 'oci/database/database'

    ext_management_system.with_provider_connection(:service => 'Database::DatabaseClient') do |connection|
      connection.create_autonomous_database(
        OCI::Database::Models::CreateAutonomousDatabaseDetails.new(
          :db_name                  => options[:name],
          :display_name             => options[:name],
          :admin_password           => options[:password],
          :cpu_core_count           => options[:cpu_cores],
          :data_storage_size_in_tbs => options[:storage],
          :compartment_id           => options[:compartment_id]
        )
      )
    end
  end

  def self.create_mysql_database(ext_management_system, options)
    require 'oci/mysql/mysql'

    subnet_id = ManageIQ::Providers::OracleCloud::NetworkManager::CloudSubnet.find(options[:subnet]).ems_ref
    ext_management_system.with_provider_connection(:service => 'Mysql::DbSystemClient') do |connection|
      connection.create_db_system(
        OCI::Mysql::Models::CreateDbSystemDetails.new(
          :display_name        => options[:name],
          :admin_username      => options[:username],
          :admin_password      => options[:password],
          :compartment_id      => options[:compartment_id],
          :shape_name          => options[:shape_name],
          :subnet_id           => subnet_id,
          :availability_domain => options[:availability_domain]
        )
      )
    end
  end
end
