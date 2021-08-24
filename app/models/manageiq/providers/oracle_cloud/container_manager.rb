ManageIQ::Providers::Kubernetes::ContainerManager.include(ActsAsStiLeafClass)

class ManageIQ::Providers::OracleCloud::ContainerManager < ManageIQ::Providers::Kubernetes::ContainerManager
  require_nested :Container
  require_nested :ContainerGroup
  require_nested :ContainerNode
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Refresher
  require_nested :RefreshWorker

  include ManageIQ::Providers::OracleCloud::ManagerMixin

  class << self
    def ems_type
      @ems_type ||= "oke".freeze
    end

    def description
      @description ||= "Oracle Kubernetes Engine".freeze
    end

    def display_name(number = 1)
      n_('Container Provider (Oracle)', 'Container Providers (Oracle)', number)
    end

    def default_port
      443
    end

    def params_for_create
      {
      }
    end

    def bearer_token(tenant, user, private_key, public_key, region, cluster_id)
      config                  = raw_connect(tenant, user, private_key, public_key, region)
      container_engine_client = OCI::ContainerEngine::ContainerEngineClient.new(:config => config)

      # Prepare a signed request
      signer = container_engine_client.api_client.instance_variable_get(:@signer)

      url = URI::HTTPS.build(
        :host => "containerengine.#{region}.oraclecloud.com",
        :path => "/cluster_request/#{cluster_id}"
      )

      params = {}
      signer.sign(:GET, url, params, nil)

      url.query = params.to_query

      Base64.urlsafe_encode64(url.to_s)
    end
  end
end
