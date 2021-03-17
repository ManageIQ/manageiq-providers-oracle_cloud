class ManageIQ::Providers::OracleCloud::Inventory::Collector::TargetCollection < ManageIQ::Providers::OracleCloud::Inventory::Collector
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  private

  def parse_targets!
    target.targets.each do |target|
    end
  end
end
