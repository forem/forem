class Fastly
  class Dictionary < BelongsToServiceAndVersion
    attr_accessor :id, :name, :service_id

    def items
      fetcher.list_dictionary_items(:service_id => service_id, :dictionary_id => id)
    end

    # Returns a Fastly::DictionaryItem corresponding to this dictionary and the +key+
    #
    # * +key+ - Key of the dictionary item
    def item(key)
      fetcher.get_dictionary_item(service_id, id, key)
    rescue Fastly::Error => e
      raise unless e.message =~ /Record not found/
    end

    def add_item(key, value)
      fetcher.create_dictionary_item(service_id: service_id, dictionary_id: id, item_key: key, item_value: value)
    end

    def update_item(key, value)
      di = items.select {|item| item.item_key.eql? key }.first
      if di
        di.item_value = value
        fetcher.update_dictionary_item(di)
      else
        add_item(key, value)
      end
    end

    def delete_item(key)
      di = items.select {|item| item.item_key.eql? key }.first
      fetcher.delete_dictionary_item(di) if di
    end

    def self.pluralize
      'dictionaries'
    end
  end
end
