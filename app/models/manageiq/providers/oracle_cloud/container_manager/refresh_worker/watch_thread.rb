class ManageIQ::Providers::OracleCloud::ContainerManager::RefreshWorker::WatchThread < ManageIQ::Providers::Kubernetes::ContainerManager::RefreshWorker::WatchThread
  def self.start!(ems, queue, entity_type, resource_version)
    auth = ems.authentication_tokens.first

    # Since we have to reconnect with a new bearer token we can't simply save the
    # connect_options for reconnecting.  We have to save the info that we need
    # to request a new bearer token from Oracle Cloud.
    connect_options = {
      :hostname    => ems.address,
      :port        => ems.port,
      :tenant_id   => ems.realm,
      :cluster_id  => ems.uid_ems,
      :region      => ems.provider_region,
      :verify_ssl  => ems.verify_ssl_mode,
      :cert_store  => ems.ssl_cert_store,
      :user_id     => auth.userid,
      :public_key  => auth.public_key,
      :private_key => auth.auth_key
    }

    new(connect_options, ems.class, queue, entity_type, resource_version).tap(&:start!)
  end

  def connection(_entity_type = nil)
    hostname, port = connect_options.values_at(:hostname, :port)
    bearer = ems_klass.bearer_token(*connect_options.values_at(:tenant_id, :user_id, :private_key, :public_key, :region, :cluster_id))

    ems_klass.raw_connect(
      hostname,
      port,
      :bearer      => bearer,
      :ssl_options => {
        :verify_ssl => connect_options[:verify_ssl],
        :cert_store => connect_options[:ssl_cert_store]
      }
    )
  end
end
