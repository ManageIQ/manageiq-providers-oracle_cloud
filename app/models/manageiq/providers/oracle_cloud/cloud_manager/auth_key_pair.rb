class ManageIQ::Providers::OracleCloud::CloudManager::AuthKeyPair < ManageIQ::Providers::CloudManager::AuthKeyPair
  OccKeyPair = Struct.new(:name, :key_name, :fingerprint, :private_key)

  def self.raw_create_key_pair(ext_management_system, create_options)
    occ = ext_management_system.connect

    name = create_options[:name]
    public_key = create_options[:public_key]

    occ.ssh_keys.create(
      :name    => name,
      :enabled => true,
      :key     => public_key
    )

    OccKeyPair.new(name, name, nil, nil)
  rescue => err
    _log.error("keypair=[#{name}], error: #{err}")
    raise MiqException::Error, err.to_s, err.backtrace
  end

  def self.validate_create_key_pair(ext_management_system, _options = {})
    if ext_management_system
      {:available => true, :message => nil}
    else
      {:available => false,
       :message   => _("The Keypair is not connected to an active %{table}") %
         {:table => ui_lookup(:table => "ext_management_system")}}
    end
  end

  def raw_delete_key_pair
    occ = resource.connect
    occ.delete_ssh_key(name)
  rescue => err
    _log.error("keypair=[#{name}], error: #{err}")
    raise MiqException::Error, err.to_s, err.backtrace
  end

  def validate_delete_key_pair
    {:available => true, :message => nil}
  end
end
