describe ManageIQ::Providers::OracleCloud::CloudManager::Refresher do
  let!(:ems) do
    FactoryBot.create(:ems_oracle_cloud_with_vcr_authentication)
  end

  describe "#refresh" do
    context "full refresh" do
      it "Performs a full refresh" do
        1.times do
          with_vcr { refresh(ems) }

          assert_ems

          assert_specific_flavor
          assert_specific_instance
          assert_specific_image
        end
      end

      def assert_ems
        expect(ems.last_refresh_error).to be_nil
        expect(ems.last_refresh_date).not_to be_nil
        expect(ems.vms.count).to eq(1)
        expect(ems.miq_templates.count).to eq(95)
        expect(ems.flavors.count).to eq(13)
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
          :genealogy_parent => ems.miq_templates.find_by(:ems_ref => "ocid1.image.oc1.iad.aaaaaaaaqdc7jslbtue7abhwvxaq3ihvazfvihhs2rwk2mvciv36v7ux5sda")
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
    end

    def with_vcr(&block)
      VCR.use_cassette(described_class.name.underscore, &block)
    end

    def refresh(targets)
      described_class.refresh(Array(targets))
    end
  end
end
