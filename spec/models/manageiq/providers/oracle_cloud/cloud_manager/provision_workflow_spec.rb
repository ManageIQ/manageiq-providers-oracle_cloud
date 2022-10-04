describe ManageIQ::Providers::OracleCloud::CloudManager::ProvisionWorkflow do
  include Spec::Support::WorkflowHelper

  let(:admin)    { FactoryBot.create(:user_with_group) }
  let(:ems)      { FactoryBot.create(:ems_oracle_cloud, :zone => zone) }
  let(:zone)     { EvmSpecHelper.local_miq_server.zone }
  let(:template) { FactoryBot.create(:template_oracle, :name => "template", :ext_management_system => ems) }
  let(:workflow) { described_class.new({:src_vm_id => template.id}, admin.userid, :skip_dialog_load => true) }

  before { stub_dialog }

  it "pass platform attributes to automate" do
    assert_automate_dialog_lookup(admin, 'cloud', 'oracle_cloud')

    described_class.new({}, admin.userid)
  end

  describe "#allowed_instance_types" do
    let!(:flavor) { FactoryBot.create(:flavor_oracle_cloud, :ext_management_system => ems) }

    it "returns the flavor" do
      expect(workflow.allowed_instance_types).to eq({flavor.id => flavor.name})
    end
  end

  describe "#allowed_cloud_tenants" do
    let!(:cloud_tenant) { FactoryBot.create(:cloud_tenant_oracle_cloud, :ext_management_system => ems) }

    it "returns the cloud tenant" do
      expect(workflow.allowed_cloud_tenants).to eq({cloud_tenant.id => cloud_tenant.name})
    end
  end

  describe "#allowed_cloud_networks" do
    let!(:cloud_tenant)  { FactoryBot.create(:cloud_tenant_oracle_cloud, :ext_management_system => ems) }
    let!(:cloud_network) { FactoryBot.create(:cloud_network_oracle_cloud, :ext_management_system => ems.network_manager, :cloud_tenant => cloud_tenant) }
    let!(:cloud_subnet)  { FactoryBot.create(:cloud_subnet_oracle, :name => "Cloud Subnet 1", :cidr => "10.1.0.0/24", :ext_management_system => ems.network_manager, :cloud_network => cloud_network, :cloud_tenant => cloud_tenant) }

    it "returns the cloud network" do
      expect(workflow.allowed_cloud_networks).to eq({cloud_network.id => cloud_network.name})
    end

    context "with two cloud tenants" do
      let!(:cloud_tenant2)  { FactoryBot.create(:cloud_tenant_oracle_cloud, :ext_management_system => ems) }
      let!(:cloud_network2) { FactoryBot.create(:cloud_network_oracle_cloud, :ext_management_system => ems.network_manager, :cloud_tenant => cloud_tenant2) }
      let!(:cloud_subnet2)  { FactoryBot.create(:cloud_subnet_oracle, :name => "Cloud Subnet 1", :cidr => "10.1.0.0/24", :ext_management_system => ems.network_manager, :cloud_network => cloud_network2, :cloud_tenant => cloud_tenant2) }

      it "returns both cloud networks" do
        expect(workflow.allowed_cloud_networks).to eq({cloud_network.id => cloud_network.name, cloud_network2.id => cloud_network2.name})
      end

      context "with a cloud tenant selected" do
        before { workflow.values[:cloud_tenant] = [cloud_tenant2.id, cloud_tenant2.name] }

        it "only returns cloud networks in the selected cloud tenant" do
          expect(workflow.allowed_cloud_networks).to eq({cloud_network2.id => cloud_network2.name})
        end
      end
    end
  end

  describe "#allowed_cloud_subnets" do
    let!(:cloud_tenant)   { FactoryBot.create(:cloud_tenant_oracle_cloud, :ext_management_system => ems) }
    let!(:cloud_network)  { FactoryBot.create(:cloud_network_oracle_cloud, :ext_management_system => ems.network_manager, :cloud_tenant => cloud_tenant) }
    let!(:cloud_subnet1) { FactoryBot.create(:cloud_subnet_oracle, :name => "Cloud Subnet 1", :cidr => "10.1.0.0/24", :ext_management_system => ems.network_manager, :cloud_network => cloud_network, :cloud_tenant => cloud_tenant) }
    let!(:cloud_subnet2) { FactoryBot.create(:cloud_subnet_oracle, :name => "Cloud Subnet 2", :cidr => "10.2.0.0/24", :ext_management_system => ems.network_manager, :cloud_network => cloud_network, :cloud_tenant => cloud_tenant) }

    context "with no cloud network selected" do
      it "returns an empty set" do
        expect(workflow.allowed_cloud_subnets).to eq({})
      end
    end

    context "with a cloud network selected" do
      before do
        workflow.values[:cloud_tenant]  = [cloud_tenant.id, cloud_tenant.name]
        workflow.values[:cloud_network] = [cloud_network.id, cloud_network.name]
      end

      it "returns the cloud subnets on the cloud network" do
        expect(workflow.allowed_cloud_subnets).to eq(
          {
            cloud_subnet1.id => "#{cloud_subnet1.name} (#{cloud_subnet1.cidr}) | #{cloud_subnet1.cloud_tenant.name}",
            cloud_subnet2.id => "#{cloud_subnet2.name} (#{cloud_subnet2.cidr}) | #{cloud_subnet2.cloud_tenant.name}"
          }
        )
      end
    end
  end
end
