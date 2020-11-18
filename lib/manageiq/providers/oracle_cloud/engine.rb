module ManageIQ
  module Providers
    module OracleCloud
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::OracleCloud

        config.autoload_paths << root.join('lib').to_s

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('Oracle Cloud Provider')
        end
      end
    end
  end
end
