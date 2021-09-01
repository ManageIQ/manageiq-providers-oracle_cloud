module ManageIQ
  module Providers::OracleCloud
    module Regions
      REGIONS = {
        "ap-chiyoda-1"     => {:name => "ap-chiyoda-1", :hostname => "https://ap-chiyoda-1.oraclecloud8.com"},
        "ap-chuncheon-1"   => {:name => "ap-chuncheon-1", :hostname => "https://ap-chuncheon-1.oraclecloud.com"},
        "ap-hyderabad-1"   => {:name => "ap-hyderabad-1", :hostname => "https://ap-hyderabad-1.oraclecloud.com"},
        "ap-mumbai-1"      => {:name => "ap-mumbai-1", :hostname => "https://ap-mumbai-1.oraclecloud.com"},
        "ap-melbourne-1"   => {:name => "ap-melbourne-1", :hostname => "https://ap-melbourne-1.oraclecloud.com"},
        "ap-osaka-1"       => {:name => "ap-osaka-1", :hostname => "https://ap-osaka-1.oraclecloud.com"},
        "ap-seoul-1"       => {:name => "ap-seoul-1", :hostname => "https://ap-seoul-1.oraclecloud.com"},
        "ap-sydney-1"      => {:name => "ap-sydney-1", :hostname => "https://ap-sydney-1.oraclecloud.com"},
        "ap-tokyo-1"       => {:name => "ap-tokyo-1", :hostname => "https://ap-tokyo-1.oraclecloud.com"},
        "ca-montreal-1"    => {:name => "ca-montreal-1", :hostname => "https://ca-montreal-1.oraclecloud.com"},
        "ca-toronto-1"     => {:name => "ca-toronto-1", :hostname => "https://ca-toronto-1.oraclecloud.com"},
        "eu-amsterdam-1"   => {:name => "eu-amsterdam-1", :hostname => "https://eu-amsterdam-1.oraclecloud.com"},
        "eu-frankfurt-1"   => {:name => "eu-frankfurt-1", :hostname => "https://eu-frankfurt-1.oraclecloud.com"},
        "eu-zurich-1"      => {:name => "eu-zurich-1", :hostname => "https://eu-zurich-1.oraclecloud.com"},
        "me-dubai-1"       => {:name => "me-dubai-1", :hostname => "https://me-dubai-1.oraclecloud.com"},
        "me-jeddah-1"      => {:name => "me-jeddah-1", :hostname => "https://me-jeddah-1.oraclecloud.com"},
        "sa-saopaulo-1"    => {:name => "sa-saopaulo-1", :hostname => "https://sa-saopaulo-1.oraclecloud.com"},
        "uk-gov-london-1"  => {:name => "uk-gov-london-1", :hostname => "https://uk-gov-london-1.oraclegovcloud.uk"},
        "uk-london-1"      => {:name => "uk-london-1", :hostname => "https://uk-london-1.oraclecloud.com"},
        "uk-gov-cardiff-1" => {:name => "uk-gov-cardiff-1", :hostname => "https://uk-gov-cardiff-1.oraclegovcloud.uk"},
        "us-phoenix-1"     => {:name => "us-phoenix-1", :hostname => "https://us-phoenix-1.oraclecloud.com"},
        "us-ashburn-1"     => {:name => "us-ashburn-1", :hostname => "https://us-ashburn-1.oraclecloud.com"},
        "us-langley-1"     => {:name => "us-langley-1", :hostname => "https://us-langley-1.oraclegovcloud.com"},
        "us-luke-1"        => {:name => "us-luke-1", :hostname => "https://us-luke-1.oraclegovcloud.com"},
        "us-sanjose-1"     => {:name => "us-sanjose-1", :hostname => "https://us-sanjose-1.oraclecloud.com"},
        "us-gov-ashburn-1" => {:name => "us-gov-ashburn-1", :hostname => "https://us-gov-ashburn-1.oraclegovcloud.com"},
        "us-gov-chicago-1" => {:name => "us-gov-chicago-1", :hostname => "https://us-gov-chicago-1.oraclegovcloud.com"},
        "us-gov-phoenix-1" => {:name => "us-gov-phoenix-1", :hostname => "https://us-gov-phoenix-1.oraclegovcloud.com"}
      }.freeze

      def self.regions
        REGIONS
      end

      def self.regions_by_hostname
        regions.values.index_by { |v| v[:hostname] }
      end

      def self.regions_for_options
        all.sort_by { |r| r[:name].downcase }.map { |r| {:label => r[:name], :value => r[:name]} }
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
