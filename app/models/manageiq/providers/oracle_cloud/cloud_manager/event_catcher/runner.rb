class ManageIQ::Providers::OracleCloud::CloudManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  def stop_event_monitor
    event_stream&.stop
  ensure
    reset_event_stream
  end

  def monitor_events
    event_monitor_running
    ensure_event_stream

    event_stream.poll { |event| process_event(event) }
  ensure
    stop_event_monitor
  end

  def process_event(event)
    _log.info("#{log_prefix} Caught event [#{event}]")
    EmsEvent.add_queue("add", @cfg[:ems_id], parse_event(event))
  end

  private

  attr_reader   :ems
  attr_accessor :event_stream

  def parse_event(event)
    ManageIQ::Providers::OracleCloud::CloudManager::EventParser.event_to_hash(event, @cfg[:ems_id])
  end

  def ensure_event_stream
    self.event_stream ||= ManageIQ::Providers::OracleCloud::CloudManager::EventCatcher::Stream.new(ems)
  end

  def reset_event_stream
    self.event_stream = nil
  end
end
