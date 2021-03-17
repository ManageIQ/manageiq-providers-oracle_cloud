describe ManageIQ::Providers::OracleCloud::CloudManager::EventParser do
  describe ".event_to_hash" do
    let(:ems) { FactoryBot.create(:ems_oracle_cloud) }

    context "vm event" do
      let(:raw_event) do
        {
          "eventType"          => "com.oraclecloud.computeapi.instanceaction.begin",
          "cloudEventsVersion" => "0.1",
          "eventTypeVersion"   => "2.0",
          "source"             => "computeApi",
          "eventTime"          => "2021-03-16T17:15:16Z",
          "contentType"        => "application/json",
          "data"               => {
            "compartmentId"      => "ocid1.tenancy.oc1..abcdefg",
            "compartmentName"    => "manageiq",
            "resourceName"       => "instance-20210223-1239",
            "resourceId"         => "ocid1.instance.oc1.iad.abcdefg",
            "availabilityDomain" => "AD3",
            "freeformTags"       => {},
            "definedTags"        => {
              "Oracle-Tags" => {
                "CreatedBy" => "oracleidentitycloudservice/accounts@manageiq.org",
                "CreatedOn" => "2021-02-23T18:38:00.683Z"
              }
            },
            "additionalDetails"  => {
              "volumeId"           => "null",
              "instanceActionType" => "softstop",
              "imageId"            => "ocid1.image.oc1.iad.aaaaaaaa",
              "X-Real-Port"        => 55_060,
              "shape"              => "VM.Standard.E2.1.Micro",
              "type"               => "CustomerVmi"
            }
          },
          "eventID"            => "25993e24-c9a4-44c2-9687-baf110f413b6",
          "extensions"         => {"compartmentId"=>"ocid1.tenancy.oc1..abcdefg"}
        }
      end

      it "parses the common event attributes" do
        parsed_hash = described_class.event_to_hash(raw_event, ems.id)
        expect(parsed_hash).to include(
          :event_type => "com.oraclecloud.computeapi.instanceaction.begin",
          :source     => "ORACLE",
          :ems_ref    => "25993e24-c9a4-44c2-9687-baf110f413b6",
          :ems_id     => ems.id,
          :timestamp  => "2021-03-16T17:15:16Z"
        )
      end

      it "includes the vm ems_ref and name in the event hash" do
        parsed_hash = described_class.event_to_hash(raw_event, ems.id)
        expect(parsed_hash).to include(
          :vm_ems_ref => "ocid1.instance.oc1.iad.abcdefg",
          :vm_name    => "instance-20210223-1239"
        )
      end
    end
  end
end
