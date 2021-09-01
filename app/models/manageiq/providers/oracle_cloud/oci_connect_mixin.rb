module ManageIQ::Providers::OracleCloud::OciConnectMixin
  extend ActiveSupport::Concern

  module ClassMethods
    def oci_config(tenant, user, private_key, public_key, region)
      require "oci"

      # Strip out any "----- BEGIN/END PUBLIC KEY -----" lines
      public_key.gsub!(/-----(BEGIN|END) PUBLIC KEY-----/, "")
      # Build a key fingerprint e.g. aa:bb:cc:dd:ee...
      fingerprint = Digest::MD5.hexdigest(Base64.decode64(public_key)).scan(/../).join(":")

      config = OCI::Config.new

      config.user        = user
      config.tenancy     = tenant
      config.key_content = ManageIQ::Password.try_decrypt(private_key)
      config.fingerprint = fingerprint
      config.region      = region

      config
    end
  end
end
