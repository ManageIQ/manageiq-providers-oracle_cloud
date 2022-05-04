module ManageIQ
  module Providers::OracleCloud
    class Regions < ManageIQ::Providers::Regions
      def self.regions_for_options
        all.sort_by { |r| r[:name].downcase }.map { |r| {:label => r[:name], :value => r[:name]} }
      end

      private_class_method def self.from_source
        require "oci/regions_definitions"
        OCI::Regions::REGION_ENUM
          .map      { |name| {:name => name} }
          .index_by { |r| r[:name] }
      end
    end
  end
end
