class ManageIQ::Providers::OracleCloud::NetworkManager::RefreshParser
  include Vmdb::Logging
  include ManageIQ::Providers::OracleCloud::RefreshHelperMethods

  def initialize(ems, options = nil)
    @ems        = ems
    @connection = ems.connect
    @data       = {}
    @data_index = {}
    @options    = options || {}
  end

  def ems_inv_to_hashes
    log_header = "Collecting data for EMS : [#{@ems.name}] id: [#{@ems.id}]"

    _log.info("#{log_header}...")

    get_cloud_networks #ipnetworks
    #get_cloud_subnets
    get_network_ports #vnics
    #get_floating_ips #ip/reservation
    #get_public_ips

    _log.info("#{log_header}...Complete")

    @data
  end

  private

  def get_cloud_networks
    ip_networks = @connection.ip_networks.all
    process_collection(ip_networks, :cloud_networks) { |ip_network| parse_cloud_network(ip_network) }
  end

  def get_network_ports
    network_ports = @connection.vnics.all
    process_collection(network_ports, :network_ports) { |n| parse_network_port(n) }
  end

  def parse_cloud_network(ip_network)
    uid    = ip_network.name

    name   = ip_network.description
    name ||= uid

    type = ManageIQ::Providers::OracleCloud::NetworkManager::CloudNetwork.name

    new_result = {
      :type                => type,
      :ems_ref             => uid,
      :name                => name,
      :cidr                => ip_network.ip_address_prefix,
      :status              => "active",
      :enabled             => true,
    }
    return uid, new_result
  end

  # Is it allowed to use _ in vnic names?
  def extract_instance(name)
    tokens = name.split('_')
    tokens.take(tokens.size - 1).join('_')
  end

  def parse_network_port(network_port)
    name = uid = parse_uid_from_url(network_port.name)

    type = ManageIQ::Providers::OracleCloud::NetworkManager::NetworkPort.name

    new_result = {
      :type                       => type,
      :name                       => name,
      :ems_ref                    => network_port.name,
      :mac_address                => network_port.mac_address,
    }

    if name.include? '_'
      device = parent_manager_fetch_name(:vms, extract_instance(name))
      new_result[:device_ref] = device.ems_ref
      new_result[:device] = device
    end
    
    return uid, new_result
  end
end
