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
    # First create the target kafka topic that we will subscribe to
    stream = find_or_create_stream!

    # Then create an events rule that will send all events to that topic
    find_or_create_rule!(stream)

    # Set up an initial cursor that will start a consumer group looking at the
    # latest events
    cursor = create_cursor!(stream)

    until should_exit.true?
      result = stream_client(stream).get_messages(stream.id, cursor)
      next if result.status != 200

      cursor = result.headers["opc-next-cursor"]

      Array(result.data).each { |message| yield decode_message(message) }

      sleep(poll_sleep)
    end
  end

  private

  def find_or_create_stream!
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

  def find_or_create_rule!(stream)
    all_rules = events_client.list_rules(compartment_id).data
    manageiq_events_rule = all_rules.select { |rule| rule.lifecycle_state == "ACTIVE" }.detect { |rule| rule.display_name == "manageiq-events" }
    return manageiq_events_rule if manageiq_events_rule.present?

    result = events_client.create_rule(
      OCI::Events::Models::CreateRuleDetails.new(
        :display_name   => "manageiq-events",
        :is_enabled     => true,
        :condition      => "{}", # this will match on all events
        :compartment_id => compartment_id,
        :actions        => OCI::Events::Models::ActionDetailsList.new(
          :actions => [OCI::Events::Models::StreamingServiceAction.new(:stream_id => stream.id)]
        )
      )
    )

    result.data
  end

  def create_cursor!(stream)
    create_cursor_details = OCI::Streaming::Models::CreateGroupCursorDetails.new(
      :type          => "LATEST",
      :group_name    => "event_catcher-#{ems.uid_ems}",
      :commit_on_get => true
    )

    stream_client(stream).create_group_cursor(stream.id, create_cursor_details).data.value
  end

  def decode_message(message)
    JSON.parse(Base64.decode64(message.value))
  end

  def events_client
    @events_client ||= ems.connect(:service => "Events::EventsClient")
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
