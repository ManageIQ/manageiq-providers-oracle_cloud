class ManageIQ::Providers::OracleCloud::CloudManager::EventCatcher::Stream
  include Vmdb::Logging

  attr_reader :ems, :should_exit

  def initialize(ems)
    @ems         = ems
    @should_exit = Concurrent::AtomicBoolean.new
  end

  def stop
    should_exit.make_true
  end

  def poll
    stream = find_or_create_manageiq_events_stream
    cursor = create_cursor(stream)

    until should_exit.true?
      messages = stream_client(stream).get_messages(stream.id, cursor.value).data
      Array(messages).each { |message| yield decode_message(message) }

      sleep(poll_sleep)
    end
  end

  private

  def find_or_create_manageiq_events_stream
    streams = stream_admin_client.list_streams(:compartment_id => compartment_id).data

    manageiq_events_stream = streams.select { |stream| stream.lifecycle_state == "ACTIVE" }.detect { |stream| stream.name == "manageiq-events" }
    manageiq_events_stream || create_manageiq_events_stream
  end

  def create_manageiq_events_stream
    _log.info("Creating event stream [miq-events]...")
    create_stream_details = OCI::Streaming::Models::CreateStreamDetails.new(
      :name           => "manageiq-events",
      :compartment_id => ems.uid_ems,
      :partitions     => 1
    )

    stream_admin_client.create_stream(create_stream_details).data
  end

  def create_cursor(stream)
    create_cursor_details = OCI::Streaming::Models::CreateCursorDetails.new(
      :type      => "LATEST",
      :partition => "0"
    )

    stream_client(stream).create_cursor(stream.id, create_cursor_details).data
  end

  def decode_message
    JSON.parse(Base64.decode64(message.value))
  end

  def stream_admin_client
    @stream_admin_client ||= ems.connect(:service => "Streaming::StreamAdminClient")
  end

  def stream_client(stream)
    @stream_client ||= {}
    @stream_client[stream.messages_endpoint] ||= ems.connect(
      :service  => "Streaming::StreamClient",
      :endpoint => stream.messages_endpoint
    )
  end

  def compartment_id
    ems.uid_ems
  end

  def poll_sleep
    5.seconds
  end
end
