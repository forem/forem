require 'cgi'

class Fastly
  class DictionaryItem < Base
    attr_accessor :dictionary_id, :item_key, :item_value, :service_id

    alias_method :key, :item_key
    alias_method :value, :item_value

    # Return the Service object this belongs to
    def service
      @service ||= fetcher.get(Service, service_id)
    end

    # :nodoc:
    def as_hash
      super.delete_if { |var| %w(service_id dictionary_id).include?(var) }
    end

    def self.get_path(service, dictionary_id, item_key, _opts = {})
      "/service/#{service}/dictionary/#{dictionary_id}/item/#{CGI::escape(item_key)}"
    end

    def self.post_path(opts)
      "/service/#{opts[:service_id]}/dictionary/#{opts[:dictionary_id]}/item"
    end

    def self.put_path(obj)
      get_path(obj.service_id, obj.dictionary_id, obj.item_key)
    end

    def self.delete_path(obj)
      put_path(obj)
    end

    def self.list_path(opts = {})
      "/service/#{opts[:service_id]}/dictionary/#{opts[:dictionary_id]}/items"
    end
  end
end
