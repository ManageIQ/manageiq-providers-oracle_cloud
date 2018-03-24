module ManageIQ::Providers::OracleCloud::RefreshHelperMethods
  extend ActiveSupport::Concern

  def process_collection(collection, key)
    @data[key] ||= []

    collection.each do |item|
      uid, new_result = yield(item)
      next if uid.nil?

      @data[key] << new_result
      @data_index.store_path(key, uid, new_result)
    end
  end

  def parse_uid_from_url(url)
    url.split('/')[-1]
  end

  def parse_name_from_url(url)
    url.split('/')[-2]
  end

  def parent_manager_fetch_path(collection, ems_ref)
    @parent_manager_data ||= {}
    return @parent_manager_data.fetch_path(collection, ems_ref) if @parent_manager_data.has_key_path?(collection,
                                                                                                      ems_ref)

    @parent_manager_data.store_path(collection,
                                    ems_ref,
                                    @ems.public_send(collection).try(:where, :ems_ref => ems_ref).try(:first))
  end

  def parent_manager_fetch_name(collection, name)
    @parent_manager_data ||= {}
    return @parent_manager_data.fetch_path(collection, name) if @parent_manager_data.has_key_path?(collection,
                                                                                                      name)

    @parent_manager_data.store_path(collection,
                                    name,
                                    @ems.public_send(collection).try(:where, :name => name).try(:first))
  end

  module ClassMethods
    def ems_inv_to_hashes(ems, options = nil)
      new(ems, options).ems_inv_to_hashes
    end
  end
end
