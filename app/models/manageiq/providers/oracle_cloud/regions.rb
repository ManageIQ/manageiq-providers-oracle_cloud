module ManageIQ
  module Providers::OracleCloud
    module Regions
      REGIONS = {
        "us2" => {
          :name        => "us2",
          :hostname    => "https://compute.uscom-central-1.oraclecloud.com/",
          :description => "US Commercial 2",
        }
      }.freeze

      def self.regions
        REGIONS
      end

      def self.regions_by_hostname
        regions.values.index_by { |v| v[:hostname] }
      end

      def self.all
        regions.values
      end

      def self.names
        regions.keys
      end

      def self.hostnames
        regions_by_hostname.keys
      end

      def self.find_by_name(name)
        regions[name]
      end

      def self.find_by_hostname(hostname)
        regions_by_hostname[hostname]
      end
    end
  end
end
