module ManageIQ::Providers
  module OracleCloud
    class CloudManager::RefreshParser < ManageIQ::Providers::CloudManager::RefreshParser
      include Vmdb::Logging
      include ManageIQ::Providers::OracleCloud::RefreshHelperMethods

      def initialize(ems, options = nil)
        @ems               = ems
        @connection        = ems.connect
        @options           = options || {}
        @data              = {}
        @data_index        = {}
      end

      def ems_inv_to_hashes
        log_header = "Collecting data for EMS : [#{@ems.name}] id: [#{@ems.id}]"

        _log.info("#{log_header}...")

        get_flavors
        get_volumes
        get_key_pairs
        get_images
        # get_snapshots
        get_instances

        _log.info("#{log_header}...Complete")

        @data
      end

      private

      def get_flavors
        flavors = @connection.shapes.all
        process_collection(flavors, :flavors) { |flavor| parse_flavor(flavor) }
      end

      def get_volumes
        disks = @connection.volumes
        process_collection(disks, :cloud_volumes) { |volume| parse_volume(volume) }
      end

      def get_key_pairs
        kps = @connection.ssh_keys
        process_collection(kps, :key_pairs) { |kp| parse_key_pair(kp) }
      end

      def get_images
        images = @connection.images.all_public
        process_collection(images, :vms) { |image| parse_storage_as_template(image) }
      end

      def get_key_pairs
        ssh_keys = @connection.ssh_keys
        process_collection(ssh_keys, :key_pairs) { |ssh_key| parse_ssh_key(ssh_key) }
      end

      def get_instances
        instances = @connection.instances
        process_collection(instances, :vms) { |instance| parse_instance(instance) }
      end

      def parse_flavor(flavor)
        uid = flavor.name

        # hardcode description from Oracle site https://docs.oracle.com/cloud/latest/computecs_common/OCSUG/GUID-1DD0FA71-AC7B-461C-B8C1-14892725AA69.htm#OCSUG210

        type = ManageIQ::Providers::OracleCloud::CloudManager::Flavor.name
        new_result = {
          :type    => type,
          :ems_ref => flavor.name,
          :name    => flavor.name,
          #:description => flavor.description,
          :enabled => true,
          :cpus    => flavor.cpus,
          :memory  => flavor.ram * 1.megabyte,
        }

        return uid, new_result
      end

      def parse_volume(volume)
        new_result = {
          :ems_ref     => volume.name,
          :name        => volume.name,
          :status      => volume.status,
          :description => parse_uid_from_url(volume.imagelist),
          :size        => volume.size,
        }

        return volume.name, new_result
      end

      def parse_storage_as_template(storage)
        uid    = storage.name
        name   = parse_uid_from_url(storage.name)
        type   = ManageIQ::Providers::OracleCloud::CloudManager::Template.name

        new_result = {
          :type               => type,
          :uid_ems            => uid,
          :ems_ref            => uid,
          :location           => storage.uri,
          :name               => name,
          :vendor             => "unknown",
          :raw_power_state    => "never",
          :operating_system   => process_os(name),
          :template           => true,
          :publicly_available => true,
          :deprecated         => false,
        }

        return uid, new_result
      end

      def process_os(name)
        product_name = OperatingSystem.normalize_os_name(name)
        {
          :product_name => product_name
        }
      end

      def parse_ssh_key(ssh_key)
        uid = ssh_key.name

        type = ManageIQ::Providers::OracleCloud::CloudManager::AuthKeyPair.name

        new_result = {
          :type        => type,
          :name        => ssh_key.name,
          :fingerprint => nil,
        }

        return uid, new_result
      end

      def parse_instance(instance)
        uid    = parse_uid_from_url(instance.name)
        name   = parse_name_from_url(instance.name)

        flavor = @data_index.fetch_path(:flavors, instance.shape)

        type = ManageIQ::Providers::OracleCloud::CloudManager::Vm.name

        #private_network = { 
        #  :description => 'private',
        #  :ipaddress   => instance.ip,
        #  :hostname    => instance.hostname,
        #}.delete_nils

        new_result = {
          :type             => type,
          :uid_ems          => uid,
          :ems_ref          => "#{name}/#{uid}",
          :name             => name,
          :vendor           => 'unknown',
          :raw_power_state  => instance.state,
          :flavor           => flavor,
          :boot_time        => instance.start_time,
          :operating_system => extract_os(instance),
          # :labels            => instance.tags,
          :hardware         => {
            :cpu_total_cores => flavor[:cpus],
            :memory_mb       => flavor[:memory] / 1.megabyte,
            :disks           => [],
         #   :networks        => [private_network]
          },
          :key_pairs        => extract_keys(instance.sshkeys),
        }

        populate_hardware_hash_with_disks(new_result[:hardware][:disks], instance)

        return uid, new_result
      end

      def extract_os(instance)
        first_disk = instance.storage_attachments.find { |item| item['index'] == instance.boot_order.first }

        first_disk_ref = first_disk.keys.include?('storage_volume_name') ? first_disk['storage_volume_name'] : first_disk['volume']

        boot_disk = @data_index.fetch_path(:cloud_volumes, first_disk_ref)

        boot_disk.nil? ? process_os(instance.platform) : process_os(boot_disk[:description])
      end

      def populate_hardware_hash_with_disks(hardware_disks_array, instance)
        instance.storage_attachments.each do |storage_attachment|
          storage_attachment_ref = storage_attachment.keys.include?('storage_volume_name') ? storage_attachment['storage_volume_name'] : storage_attachment['volume']

          d = @data_index.fetch_path(:cloud_volumes, storage_attachment_ref)

          next if d.nil?

          disk_size     = d[:size].to_i
          disk_name     = storage_attachment_ref
          disk_location = storage_attachment['index']

          disk = add_instance_disk(hardware_disks_array, disk_size, disk_name, disk_location)
          disk[:backing]      = d
          disk[:backing_type] = 'CloudVolume'
        end
      end

      def add_instance_disk(disks, size, name, location)
        super(disks, size, location, name, "oracle")
      end

      def extract_keys(ssh_keys)
        return [] if ssh_keys.nil?
        key_pairs = []
        ssh_keys.each do |ssh_key|
          key_pairs << @data_index.fetch_path(:key_pairs, ssh_key)
        end

        key_pairs
      end
    end
  end
end
