class ManageIQ::Providers::OracleCloud::CloudManager::ProvisionWorkflow < ManageIQ::Providers::CloudManager::ProvisionWorkflow
  def dialog_name_from_automate(message = 'get_dialog_name')
    super(message, {'platform' => 'oracle_cloud'})
  end

  def allowed_instance_types(_options = {})
    source = load_ar_obj(get_source_vm)
    ems = get_targets_for_ems(source, :cloud_filter, Flavor, 'flavors')
    ems.each_with_object({}) { |f, h| h[f.id] = display_name_for_name_description(f) }
  end

  def allowed_cloud_tenants(_options = {})
    source = load_ar_obj(get_source_vm)
    ems = get_targets_for_ems(source, :cloud_filter, CloudTenant, 'cloud_tenants')
    ems.each_with_object({}) { |f, h| h[f.id] = f.name }
  end

  def allowed_cloud_networks(_options = {})
    return {} unless (src = provider_or_tenant_object)

    targets = get_targets_for_source(src, :cloud_filter, CloudNetwork, 'all_cloud_networks')
    targets = filter_cloud_networks(targets)
    allowed_ci(:cloud_network, [:cloud_tenant], targets.map(&:id))
  end

  def allowed_cloud_subnets(_options = {})
    src = resources_for_ui
    if (cn = CloudNetwork.find_by(:id => src[:cloud_network_id]))
      targets = get_targets_for_source(cn, :cloud_filter, CloudNetwork, 'cloud_subnets')
      targets.each_with_object({}) do |cs, hash|
        hash[cs.id] = "#{cs.name} (#{cs.cidr}) | #{cs.cloud_tenant.try(:name)}"
      end
    else
      {}
    end
  end

  def cloud_tenant_to_cloud_network(src)
    if src[:cloud_tenant]
      load_ar_obj(src[:cloud_tenant]).cloud_networks.each_with_object({}) do |cn, hash|
        hash[cn.id] = cloud_network_display_name(cn)
      end
    else
      load_ar_obj(src[:ems]).all_cloud_networks.each_with_object({}) do |cn, hash|
        hash[cn.id] = cloud_network_display_name(cn)
      end
    end
  end

  def filter_cloud_networks(networks)
    networks.select do |cloud_network|
      cloud_network.cloud_subnets.any?
    end
  end
end
