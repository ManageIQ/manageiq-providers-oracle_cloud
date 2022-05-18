class ManageIQ::Providers::OracleCloud::CloudManager::CloudDatabase < ::CloudDatabase
  supports :create
  supports :delete
  supports :update

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

  def params_for_update
    {
      :fields => [
        {
          :component => 'text-field',
          :id        => 'name',
          :name      => 'name',
          :label     => _('Rename Cloud Database'),
        }
      ],
    }
  end

  def raw_update_cloud_database(options)
    check_database_type == :oracle ? update_oracle_database(options) : update_mysql_database(options)
  rescue => err
    _log.error("cloud database=[#{name}], error: #{err}")
    raise
  end

  def update_oracle_database(options)
    with_provider_connection(:service => 'Database::DatabaseClient') do |connection|
      connection.update_autonomous_database(
        ems_ref,
        OCI::Database::Models::UpdateAutonomousDatabaseDetails.new(
          :display_name => options[:name]
        )
      )
    end
  end

  def update_mysql_database(options)
    with_provider_connection(:service => 'Mysql::DbSystemClient') do |connection|
      connection.update_db_system(
        ems_ref,
        OCI::Mysql::Models::UpdateDbSystemDetails.new(:display_name => options[:name])
      )
    end
  end

  def raw_delete_cloud_database
    check_database_type == :oracle ? delete_oracle_database : delete_mysql_database
  rescue => err
    _log.error("cloud database=[#{name}], error: #{err}")
    raise
  end

  def delete_oracle_database
    with_provider_connection(:service => 'Database::DatabaseClient') do |connection|
      connection.delete_autonomous_database(ems_ref)
    end
  end

  def delete_mysql_database
    with_provider_connection(:service => 'Mysql::DbSystemClient') do |connection|
      connection.delete_db_system(ems_ref)
    end
  end

  def check_database_type
    db_engine.include?("Oracle Database") ? :oracle : :mysql
  end
end
