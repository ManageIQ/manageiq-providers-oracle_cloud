# Load KubernetesEventCatcherBase from the manageiq-providers-kubernetes gem.
# In production the gem is installed via the inline gemfile in the worker binary.
# In development/test the local checkout is used via the path gem in Gemfile.
k8s_base = if (spec = Gem.loaded_specs['manageiq-providers-kubernetes'])
               File.join(spec.gem_dir, 'lib/manageiq/providers/kubernetes/workers/event_catcher_base')
             else
               File.expand_path('../../../manageiq-providers-kubernetes/lib/manageiq/providers/kubernetes/workers/event_catcher_base', __dir__)
             end
require k8s_base

require 'base64'
require 'digest'
require 'oci'

class EventCatcher < KubernetesEventCatcherBase
  # OKE cluster request tokens are valid for 21 seconds per OCI documentation.
  OKE_TOKEN_TTL = 21

  attr_reader :token_expiry

  private

  def auth_options
    @token_expiry = Time.now.utc + OKE_TOKEN_TTL
    {:bearer_token => oke_token}
  end

  def oke_token
    config                  = oci_config
    container_engine_client = OCI::ContainerEngine::ContainerEngineClient.new(:config => config)
    signer                  = container_engine_client.api_client.instance_variable_get(:@signer)

    url = URI::HTTPS.build(
      :host => "containerengine.#{ems['provider_region']}.oraclecloud.com",
      :path => "/cluster_request/#{ems['uid_ems']}"
    )

    params = {}
    signer.sign(:GET, url, params, nil)
    url.query = params.to_query

    Base64.urlsafe_encode64(url.to_s)
  end

  def oci_config
    public_key  = authentication['public_key'].dup
    private_key = authentication['auth_key']

    # Strip PEM header/footer lines — OCI expects only the raw base64 body
    public_key.gsub!(/-----(BEGIN|END) PUBLIC KEY-----/, "")

    fingerprint = Digest::MD5.hexdigest(Base64.decode64(public_key)).scan(/../).join(":")

    config             = OCI::Config.new
    config.tenancy     = ems['realm']
    config.user        = authentication['userid']
    config.key_content = private_key
    config.fingerprint = fingerprint
    config.region      = ems['provider_region']
    config
  end

  def log_prefix
    'MIQ(ManageIQ::Providers::OracleCloud::ContainerManager::EventCatcher)'
  end
end
