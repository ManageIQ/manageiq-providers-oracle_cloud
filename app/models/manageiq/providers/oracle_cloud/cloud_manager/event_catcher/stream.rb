class ManageIQ::Providers::OracleCloud::CloudManager::EventCatcher::Stream
  attr_reader :ems

  def initialize(ems)
    @ems = ems
  end

  def stop
  end

  def poll
    loop do
      sleep(1)
    end
  end
end
