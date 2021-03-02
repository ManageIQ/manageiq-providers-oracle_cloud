describe ManageIQ::Providers::OracleCloud::CloudManager::Refresher do
  let!(:ems) do
    FactoryBot.create(:ems_oracle_cloud_with_vcr_authentication)
  end

  describe "#refresh" do
    context "full refresh" do
      it "Performs a full refresh" do
        2.times do
          with_vcr { refresh(ems) }

          assert_ems

          assert_specific_cloud_tenant
          assert_specific_flavor
          assert_specific_instance
          assert_specific_image
          assert_specific_cloud_network
          assert_specific_cloud_subnet
        end
      end

      def assert_ems
        expect(ems.last_refresh_error).to be_nil
        expect(ems.last_refresh_date).not_to be_nil
        expect(ems.vms.count).to eq(1)
        expect(ems.miq_templates.count).to eq(98)
        expect(ems.flavors.count).to eq(13)
        expect(ems.cloud_tenants.count).to eq(3)
        expect(ems.cloud_subnets.count).to eq(1)
        expect(ems.cloud_networks.count).to eq(1)
        expect(ems.network_ports.count).to eq(1)
      end

      def assert_specific_cloud_tenant
        cloud_tenant = ems.cloud_tenants.find_by(:ems_ref => "ocid1.tenancy.oc1..aaaaaaaa")
        expect(cloud_tenant).to have_attributes(
          :ems_ref     => "ocid1.tenancy.oc1..aaaaaaaa",
          :name        => "manageiq",
          :description => "manageiq",
          :enabled     => true,
          :parent      => nil
        )
      end

      def assert_specific_flavor
        flavor = ems.flavors.find_by(:ems_ref => "VM.Standard.E2.1.Micro")
        expect(flavor).to have_attributes(
          :name    => "VM.Standard.E2.1.Micro",
          :cpus    => 1,
          :memory  => 1.gigabyte,
          :ems_ref => "VM.Standard.E2.1.Micro",
          :type    => "ManageIQ::Providers::OracleCloud::CloudManager::Flavor"
        )
      end

      def assert_specific_instance
        vm = ems.vms.find_by(:ems_ref => "ocid1.instance.oc1.iad.anuwcljtw3enqvycv47dx6ewcsmpjqzazpqxblsikzzkiw7ubhhgopqf3i3q")
        expect(vm).to have_attributes(
          :vendor           => "oracle",
          :name             => "instance-20210223-1239",
          :location         => "ocid1.tenancy.oc1..aaaaaaaa",
          :uid_ems          => "ocid1.instance.oc1.iad.anuwcljtw3enqvycv47dx6ewcsmpjqzazpqxblsikzzkiw7ubhhgopqf3i3q",
          :power_state      => "on",
          :type             => "ManageIQ::Providers::OracleCloud::CloudManager::Vm",
          :ems_ref          => "ocid1.instance.oc1.iad.anuwcljtw3enqvycv47dx6ewcsmpjqzazpqxblsikzzkiw7ubhhgopqf3i3q",
          :flavor           => ems.flavors.find_by(:ems_ref => "VM.Standard.E2.1.Micro"),
          :raw_power_state  => "RUNNING",
          :genealogy_parent => ems.miq_templates.find_by(:ems_ref => "ocid1.image.oc1.iad.aaaaaaaaqdc7jslbtue7abhwvxaq3ihvazfvihhs2rwk2mvciv36v7ux5sda"),
          :cloud_tenant     => ems.cloud_tenants.find_by(:ems_ref => "ocid1.tenancy.oc1..aaaaaaaa")
        )

        expect(vm.network_ports.count).to eq(1)
        expect(vm.network_ports.first).to have_attributes(
          :ems_ref      => "ocid1.vnic.oc1.iad.abuwcljt5ddcgxptz6arjcdfpje74zydmpfrpqeg2kjkbwiax26rwo36nzfa",
          :name         => "instance-20210223-1239",
          :type         => "ManageIQ::Providers::OracleCloud::NetworkManager::NetworkPort",
          :mac_address  => "02:00:17:09:70:43",
          :status       => "AVAILABLE",
          :device       => vm,
          :cloud_tenant => ems.cloud_tenants.find_by(:ems_ref => "ocid1.tenancy.oc1..aaaaaaaa")
        )

        expect(vm.cloud_subnets.count).to eq(1)
        expect(vm.cloud_subnets.first).to have_attributes(
          :ems_ref       => "ocid1.subnet.oc1.iad.aaaaaaaanmzazihpr74jpktyicjibszf3dyye4tho43nxemsixabsc7ugdqq",
          :name          => "subnet-20210223-1239",
          :cloud_network => ems.cloud_networks.find_by(:ems_ref => "ocid1.vcn.oc1.iad.amaaaaaaw3enqvya24pw6a2kqhuwllzk5447qch6cdemiqvxdlnahagepodq"),
          :cidr          => "10.0.0.0/24",
          :status        => "AVAILABLE",
          :gateway       => "10.0.0.1",
          :cloud_tenant  => ems.cloud_tenants.find_by(:ems_ref => "ocid1.tenancy.oc1..aaaaaaaa"),
          :type          => "ManageIQ::Providers::OracleCloud::NetworkManager::CloudSubnet"
        )
      end

      def assert_specific_image
        template = ems.miq_templates.find_by(:ems_ref => "ocid1.image.oc1.iad.aaaaaaaaqdc7jslbtue7abhwvxaq3ihvazfvihhs2rwk2mvciv36v7ux5sda")
        expect(template).to have_attributes(
          :vendor          => "oracle",
          :name            => "Oracle-Linux-7.9-2021.01.12-0",
          :location        => "unknown",
          :uid_ems         => "ocid1.image.oc1.iad.aaaaaaaaqdc7jslbtue7abhwvxaq3ihvazfvihhs2rwk2mvciv36v7ux5sda",
          :power_state     => "never",
          :type            => "ManageIQ::Providers::OracleCloud::CloudManager::Template",
          :ems_ref         => "ocid1.image.oc1.iad.aaaaaaaaqdc7jslbtue7abhwvxaq3ihvazfvihhs2rwk2mvciv36v7ux5sda",
          :raw_power_state => "never"
        )

        expect(template.hardware).to have_attributes(
          :guest_os            => "linux_oracle",
          :size_on_disk        => 50_010_783_744,
          :virtualization_type => "NATIVE",
          :root_device_type    => "PARAVIRTUALIZED"
        )
        expect(template.operating_system).to have_attributes(
          :product_name => "Oracle Linux 7.9"
        )
      end

      def assert_specific_cloud_network
        cloud_network = ems.cloud_networks.first
        expect(cloud_network).to have_attributes(
          :name         => "vcn-20210223-1239",
          :ems_ref      => "ocid1.vcn.oc1.iad.amaaaaaaw3enqvya24pw6a2kqhuwllzk5447qch6cdemiqvxdlnahagepodq",
          :cidr         => "10.0.0.0/16",
          :status       => "AVAILABLE",
          :cloud_tenant => ems.cloud_tenants.find_by(:ems_ref => "ocid1.tenancy.oc1..aaaaaaaa"),
          :type         => "ManageIQ::Providers::OracleCloud::NetworkManager::CloudNetwork"
        )
      end

      def assert_specific_cloud_subnet
        cloud_subnet = ems.cloud_subnets.first
        expect(cloud_subnet).to have_attributes(
          :name          => "subnet-20210223-1239",
          :ems_ref       => "ocid1.subnet.oc1.iad.aaaaaaaanmzazihpr74jpktyicjibszf3dyye4tho43nxemsixabsc7ugdqq",
          :cloud_network => ems.cloud_networks.find_by(:ems_ref => "ocid1.vcn.oc1.iad.amaaaaaaw3enqvya24pw6a2kqhuwllzk5447qch6cdemiqvxdlnahagepodq"),
          :cidr          => "10.0.0.0/24",
          :status        => "AVAILABLE",
          :gateway       => "10.0.0.1",
          :cloud_tenant  => ems.cloud_tenants.find_by(:ems_ref => "ocid1.tenancy.oc1..aaaaaaaa"),
          :type          => "ManageIQ::Providers::OracleCloud::NetworkManager::CloudSubnet"
        )
      end
    end

    def with_vcr(&block)
      VCR.use_cassette(described_class.name.underscore, &block)
    end

    def refresh(targets)
      described_class.refresh(Array(targets))
    end
  end
end
