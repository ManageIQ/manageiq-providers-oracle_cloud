namespace :oracle do
  namespace :regions do
    desc "Update list of regions"
    task :update => :environment do
      File.write("config/regions.yml", regions.to_yaml)
    end

    def regions
      require "oci"
      OCI::Regions::REGION_ENUM
        .map      { |name| {:name => name} }
        .index_by { |r| r[:name] }
    end
  end
end
