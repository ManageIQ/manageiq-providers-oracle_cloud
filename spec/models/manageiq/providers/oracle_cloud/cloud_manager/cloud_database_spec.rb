describe ManageIQ::Providers::OracleCloud::CloudManager::CloudDatabase do
  let(:ems) do
    FactoryBot.create(:ems_oracle_cloud)
  end

  let(:cloud_database) do
    FactoryBot.create(:cloud_database_oracle, :ext_management_system => ems, :name => "test-db", :db_engine => db_engine)
  end

  describe "#create_database" do
    context "with an oracle database" do
      require 'oci/database/database'

      let(:connection) do
        double("OCI::Database::DatabaseClient")
      end

      let(:db_engine) { "Oracle Database" }

      before do
        allow(ems).to receive(:with_provider_connection).and_yield(connection)
      end

      it 'creates an Oracle database' do
        expect(connection).to receive(:create_autonomous_database).with(OCI::Database::Models::CreateAutonomousDatabaseDetails.new(
                                                                          :db_name                  => cloud_database.name,
                                                                          :display_name             => cloud_database.name,
                                                                          :admin_password           => "test123",
                                                                          :cpu_core_count           => 1,
                                                                          :data_storage_size_in_tbs => 1,
                                                                          :compartment_id           => "ocid1.tenancy.oc1..aaaaaaaag6mtonzmundadix23pw4ygwkha3bu3yenzryclsvblo5tg2qadrq"
                                                                        ))

        cloud_database.class.raw_create_cloud_database(ems, {"name"           => cloud_database.name,
                                                             "compartment_id" => "ocid1.tenancy.oc1..aaaaaaaag6mtonzmundadix23pw4ygwkha3bu3yenzryclsvblo5tg2qadrq",
                                                             "database"       => "oracle",
                                                             "password"       => "test123",
                                                             "cpu_cores"      => 1,
                                                             "storage"        => 1})
      end
    end

    context "with a MySQL database" do
      require 'oci/mysql/mysql'

      let(:connection) do
        double("OCI::Mysql::DbSystemClient")
      end

      let(:cloud_subnet) do
        FactoryBot.create(:cloud_subnet_oracle)
      end

      let(:db_engine) { "MySQL" }

      before do
        allow(ems).to receive(:with_provider_connection).and_yield(connection)
      end

      it 'creates a MySQL database' do
        expect(connection).to receive(:create_db_system).with(OCI::Mysql::Models::CreateDbSystemDetails.new(
                                                                :display_name        => cloud_database.name,
                                                                :admin_username      => "user123",
                                                                :admin_password      => "test123",
                                                                :shape_name          => "MySQL.VM.Standard.E3.1.8GB",
                                                                :subnet_id           => cloud_subnet.ems_ref,
                                                                :availability_domain => "Foha:US-ASHBURN-AD-1",
                                                                :compartment_id      => "ocid1.tenancy.oc1..aaaaaaaag6mtonzmundadix23pw4ygwkha3bu3yenzryclsvblo5tg2qadrq"
                                                              ))

        cloud_database.class.raw_create_cloud_database(ems, {"name"                => cloud_database.name,
                                                             "compartment_id"      => "ocid1.tenancy.oc1..aaaaaaaag6mtonzmundadix23pw4ygwkha3bu3yenzryclsvblo5tg2qadrq",
                                                             "database"            => "mysql",
                                                             "username"            => "user123",
                                                             "password"            => "test123",
                                                             "shape_name"          => "MySQL.VM.Standard.E3.1.8GB",
                                                             "subnet"              => cloud_subnet.id.to_s,
                                                             "availability_domain" => "Foha:US-ASHBURN-AD-1"})
      end
    end
  end

  describe "#update_database" do
    context "with an oracle database" do
      require 'oci/database/database'

      let(:connection) do
        double("OCI::Database::DatabaseClient")
      end

      let(:db_engine) { "Oracle Database" }

      before do
        allow(ems).to receive(:with_provider_connection).and_yield(connection)
      end

      it 'updates the Oracle database' do
        expect(connection).to receive(:update_autonomous_database).with(
          cloud_database.ems_ref,
          OCI::Database::Models::UpdateAutonomousDatabaseDetails.new(:display_name => "test-db123")
        )
        cloud_database.update_cloud_database({"name" => "test-db123"})
      end
    end

    context "with a MySQL database" do
      require 'oci/mysql/mysql'

      let(:connection) do
        double("OCI::Mysql::DbSystemClient")
      end

      let(:db_engine) { "MySQL" }

      before do
        allow(ems).to receive(:with_provider_connection).and_yield(connection)
      end

      it 'updates the MySQL database' do
        expect(connection).to receive(:update_db_system).with(
          cloud_database.ems_ref,
          OCI::Mysql::Models::UpdateDbSystemDetails.new(:display_name => "test-db123")
        )
        cloud_database.update_cloud_database({"name" => "test-db123"})
      end
    end
  end

  describe "#delete_database" do
    context "with an oracle database" do
      let(:connection) do
        double("OCI::Database::DatabaseClient")
      end

      let(:db_engine) { "Oracle Database" }

      before do
        allow(ems).to receive(:with_provider_connection).and_yield(connection)
      end

      it 'deletes the Oracle database' do
        expect(connection).to receive(:delete_autonomous_database).with(cloud_database.ems_ref)
        cloud_database.delete_cloud_database
      end
    end

    context "with a MySQL database" do
      let(:connection) do
        double("OCI::Mysql::DbSystemClient")
      end

      let(:db_engine) { "MySQL" }

      before do
        allow(ems).to receive(:with_provider_connection).and_yield(connection)
      end

      it 'deletes the MySQL database' do
        expect(connection).to receive(:delete_db_system).with(cloud_database.ems_ref)
        cloud_database.delete_cloud_database
      end
    end
  end
end
