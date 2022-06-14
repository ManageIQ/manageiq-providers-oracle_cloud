class ManageIQ::Providers::OracleCloud::CloudManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  def stop_event_monitor
    event_stream&.stop
  ensure
    reset_event_stream
  end

  def monitor_events
    event_monitor_running
    ensure_event_stream

    event_stream.poll do |events|
      @queue.enq(events)
      sleep_poll_normal
    end
  ensure
    stop_event_monitor
  end

  def process_event(event)
    if filtered?(event)
      _log.debug("#{log_prefix} Skipping filtered event #{event["eventType"]}")
    else
      _log.info("#{log_prefix} Caught event [#{event["eventType"]}] [#{event}]")
      EmsEvent.add_queue("add", ems_id, parse_event(event))
    end
  end

  private

  attr_reader :ems, :event_stream

  def parse_event(event)
    ManageIQ::Providers::OracleCloud::CloudManager::EventParser.event_to_hash(event, ems_id)
  end

  def filtered?(event)
    filtered_events.include?(event["eventType"])
  end

  def ensure_event_stream
    @event_stream ||= ManageIQ::Providers::OracleCloud::CloudManager::EventCatcher::Stream.new(ems)
  end

  def reset_event_stream
    @event_stream = nil
  end

  def ems_id
    @cfg[:ems_id]
  end
end
