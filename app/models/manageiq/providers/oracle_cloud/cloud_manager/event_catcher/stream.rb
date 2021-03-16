class ManageIQ::Providers::OracleCloud::CloudManager::EventCatcher::Stream
  attr_reader :ems

  def initialize(ems)
    @ems = ems
  end

  def stop
  end

  def poll
    stream = find_or_create_manageiq_events_stream

    loop do
      sleep(1)
    end
  end

  private

  def find_or_create_manageiq_events_stream
    streams = stream_admin_client.list_streams(:compartment_id => compartment_id).data

    manageiq_events_stream = streams.detect { |stream| stream.name == "manageiq-events" }
    manageiq_events_stream || create_manageiq_events_stream
  end

  def create_manageiq_events_stream
    create_stream_details = OCI::Streaming::Models::CreateStreamDetails.new(
      :name           => "manageiq-events",
      :compartment_id => ems.uid_ems,
      :partitions     => 1,
      :stream_pool_id => default_stream_pool&.id
    )

    stream_admin_client.create_stream(create_stream_details).data
  end

  def default_stream_pool
    stream_pools = stream_admin_client.list_stream_pools(:compartment_id => compartment_id).data
    stream_pools.detect { |stream_pool| stream_pool.name == "DefaultPool" }
  end

  def stream_admin_client
    @stream_admin_client ||= ems.connect(:service => "Streaming::StreamAdminClient")
  end

  def compartment_id
    ems.uid_ems
  end
end
