describe ManageIQ::Providers::OracleCloud::CloudManager::CloudDatabase do
  let(:ems) do
    FactoryBot.create(:ems_oracle_cloud)
  end

  let(:cloud_database) do
    FactoryBot.create(:cloud_database_oracle, :ext_management_system => ems, :name => "test-db")
  end

  describe 'cloud database actions' do
    context '#create_oracle_database' do
      require 'oci/database/database'

      let(:connection) do
        double("OCI::Database::DatabaseClient")
      end

      let(:db_info) do
        double("OCI::Database::Models::CreateAutonomousDatabaseDetails")
      end

      before do
        allow(ems).to receive(:with_provider_connection).and_yield(connection)
      end

      it 'creates an Oracle database' do
        expect(OCI::Database::Models::CreateAutonomousDatabaseDetails)
          .to receive(:new).with(:db_name                  => cloud_database.name,
                                 :display_name             => cloud_database.name,
                                 :admin_password           => "test123",
                                 :cpu_core_count           => 1,
                                 :data_storage_size_in_tbs => 1,
                                 :compartment_id           => "ocid1.tenancy.oc1..aaaaaaaag6mtonzmundadix23pw4ygwkha3bu3yenzryclsvblo5tg2qadrq").and_return(db_info)
        expect(connection).to receive(:create_autonomous_database).and_return(db_info)

        cloud_database.class.raw_create_cloud_database(ems, {:name           => cloud_database.name,
                                                             :compartment_id => "ocid1.tenancy.oc1..aaaaaaaag6mtonzmundadix23pw4ygwkha3bu3yenzryclsvblo5tg2qadrq",
                                                             :database       => "oracle",
                                                             :password       => "test123",
                                                             :cpu_cores      => 1,
                                                             :storage        => 1})
      end

      context '#create_mysql_database' do
        require 'oci/mysql/mysql'

        let(:connection) do
          double("OCI::Mysql::DbSystemClient")
        end

        let(:db_info) do
          double("OCI::Mysql::Models::CreateDbSystemDetails")
        end

        let(:cloud_subnet) do
          FactoryBot.create(:cloud_subnet_oracle)
        end

        before do
          allow(ems).to receive(:with_provider_connection).and_yield(connection)
        end

        it 'creates a MySQL database' do
          expect(OCI::Mysql::Models::CreateDbSystemDetails)
            .to receive(:new).with(:display_name        => cloud_database.name,
                                   :admin_username      => "user123",
                                   :admin_password      => "test123",
                                   :shape_name          => "MySQL.VM.Standard.E3.1.8GB",
                                   :subnet_id           => cloud_subnet.ems_ref,
                                   :availability_domain => "Foha:US-ASHBURN-AD-1",
                                   :compartment_id      => "ocid1.tenancy.oc1..aaaaaaaag6mtonzmundadix23pw4ygwkha3bu3yenzryclsvblo5tg2qadrq").and_return(db_info)
          expect(connection).to receive(:create_db_system).and_return(db_info)

          cloud_database.class.raw_create_cloud_database(ems, {:name                => cloud_database.name,
                                                               :compartment_id      => "ocid1.tenancy.oc1..aaaaaaaag6mtonzmundadix23pw4ygwkha3bu3yenzryclsvblo5tg2qadrq",
                                                               :database            => "mysql",
                                                               :username            => "user123",
                                                               :password            => "test123",
                                                               :shape_name          => "MySQL.VM.Standard.E3.1.8GB",
                                                               :subnet              => cloud_subnet.id.to_s,
                                                               :availability_domain => "Foha:US-ASHBURN-AD-1"})
        end
      end
    end
  end
end
