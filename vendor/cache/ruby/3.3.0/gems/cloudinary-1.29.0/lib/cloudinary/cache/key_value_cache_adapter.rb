require 'digest'
module Cloudinary::Cache
  class KeyValueCacheAdapter < CacheAdapter
    def get(public_id, type, resource_type, transformation, format)
      key = generate_cache_key(public_id, type, resource_type, transformation, format)
      @storage.get(key)
    end

    def set(public_id, type, resource_type, transformation, format, value)
      key = generate_cache_key(public_id, type, resource_type, transformation, format)
      @storage.set(key, value)
    end

    def flush_all()
      @storage.flush_all()
    end

    private

    def generate_cache_key(public_id, type, resource_type, transformation, format)
      Digest::SHA1.hexdigest [public_id, type, resource_type, transformation, format].reject(&:blank?)
    end

  end
end