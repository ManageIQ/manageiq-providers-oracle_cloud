require 'kubeclient'
require 'recursive-open-struct'
require 'oci'

require_relative '../../../workers/container_event_catcher/event_catcher'

RSpec.describe EventCatcher do
  let(:ems) do
    {
      'id'              => 1,
      'uid_ems'         => 'ocid1.cluster.oc1.phx.my-cluster',
      'type'            => 'ManageIQ::Providers::OracleCloud::ContainerManager',
      'ems_type'        => 'oke',
      'realm'           => 'ocid1.tenancy.oc1..mytenancy',
      'provider_region' => 'us-phoenix-1'
    }
  end
  let(:endpoint)       { {'hostname' => 'oke.example.com', 'port' => 6443, 'security_protocol' => 'ssl-with-validation'} }
  let(:authentication) do
    {
      'authtype'   => 'bearer',
      'userid'     => 'ocid1.user.oc1..myuser',
      'auth_key'   => "-----BEGIN RSA PRIVATE KEY-----\nfake-private-key\n-----END RSA PRIVATE KEY-----",
      'public_key' => "-----BEGIN PUBLIC KEY-----\nZmFrZS1wdWJsaWMta2V5\n-----END PUBLIC KEY-----"
    }
  end
  let(:settings)       { {'ems' => {'ems_oke' => {'blacklisted_event_names' => []}}} }
  let(:logger)         { instance_double('Logger', :info => nil, :warn => nil) }
  let(:catcher)        { described_class.new(ems, endpoint, authentication, settings, {}, logger) }

  let(:fake_token)  { 'aHR0cHM6Ly9jb250YWluZXJlbmdpbmUudXMtcGhvZW5peC0xLm9yYWNsZWNsb3VkLmNvbS9jbHVzdGVyX3JlcXVlc3Qvc2lnbmVk' }
  let(:fake_signer) { instance_double('OCI::Signer') }
  let(:fake_api_client) { instance_double('OCI::ApiClient', :instance_variable_get => fake_signer) }
  let(:fake_client) { instance_double('OCI::ContainerEngine::ContainerEngineClient', :api_client => fake_api_client) }

  before do
    allow(OCI::Config).to receive(:new).and_return(OCI::Config.allocate)
    allow(OCI::ContainerEngine::ContainerEngineClient).to receive(:new).and_return(fake_client)
    allow(fake_signer).to receive(:sign) do |_method, url, params, _body|
      params['Authorization'] = 'Signature fake'
      url
    end
    allow(Base64).to receive(:urlsafe_encode64).and_return(fake_token)
  end

  describe '#log_prefix' do
    it 'returns the OracleCloud ContainerManager class name' do
      expect(catcher.send(:log_prefix)).to eq('MIQ(ManageIQ::Providers::OracleCloud::ContainerManager::EventCatcher)')
    end
  end

  describe '#auth_options' do
    it 'returns a bearer_token hash' do
      expect(catcher.send(:auth_options)).to eq(:bearer_token => fake_token)
    end

    it 'sets @token_expiry to OKE_TOKEN_TTL seconds from now' do
      before_call = Time.now.utc
      catcher.send(:auth_options)
      expect(catcher.send(:token_expiry)).to be_within(2).of(before_call + EventCatcher::OKE_TOKEN_TTL)
    end

    it 'builds a signed URL against the correct OKE endpoint' do
      expect(fake_signer).to receive(:sign) do |method, url, _params, _body|
        expect(method).to eq(:GET)
        expect(url.host).to eq("containerengine.#{ems['provider_region']}.oraclecloud.com")
        expect(url.path).to eq("/cluster_request/#{ems['uid_ems']}")
        url
      end

      catcher.send(:auth_options)
    end

    it 'Base64 encodes the signed URL' do
      expect(Base64).to receive(:urlsafe_encode64).and_return(fake_token)
      catcher.send(:auth_options)
    end
  end

  describe '#token_expiry' do
    it 'returns nil before auth_options is called' do
      expect(catcher.send(:token_expiry)).to be_nil
    end

    it 'returns a Time ~OKE_TOKEN_TTL seconds in the future after auth_options is called' do
      before_call = Time.now.utc
      catcher.send(:auth_options)
      expect(catcher.send(:token_expiry)).to be_within(2).of(before_call + EventCatcher::OKE_TOKEN_TTL)
    end
  end

  describe '#build_client' do
    let(:fake_kubeclient) { instance_double('Kubeclient::Client', :discover => nil) }

    it 'passes the OKE token as bearer_token to Kubeclient::Client' do
      expect(Kubeclient::Client).to receive(:new) do |_uri, _version, opts|
        expect(opts[:auth_options]).to eq(:bearer_token => fake_token)
        fake_kubeclient
      end

      catcher.send(:build_client)
    end

    it 'fetches a fresh token on every build_client call' do
      allow(Kubeclient::Client).to receive(:new).and_return(fake_kubeclient)
      expect(fake_signer).to receive(:sign).twice do |_method, url, params, _body|
        params['Authorization'] = 'Signature fake'
        url
      end

      catcher.send(:build_client)
      catcher.send(:build_client)
    end
  end

  describe '#oci_config' do
    it 'sets tenancy from ems realm' do
      config = catcher.send(:oci_config)
      expect(config.tenancy).to eq(ems['realm'])
    end

    it 'sets user from authentication userid' do
      config = catcher.send(:oci_config)
      expect(config.user).to eq(authentication['userid'])
    end

    it 'sets region from ems provider_region' do
      config = catcher.send(:oci_config)
      expect(config.region).to eq(ems['provider_region'])
    end
  end
end
