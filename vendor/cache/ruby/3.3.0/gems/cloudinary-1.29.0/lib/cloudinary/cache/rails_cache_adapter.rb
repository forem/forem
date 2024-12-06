module Cloudinary::Cache
  class RailsCacheAdapter < CacheAdapter

    def flush_all
    end

    def get(public_id, type, resource_type, transformation, format)
      key = generate_cache_key(public_id, type, resource_type, transformation, format)
      Rails.cache.read(key)
    end

    def init
      unless defined? Rails
        raise CloudinaryException.new "Rails is required in order to use RailsCacheAdapter"
      end
    end

    def set(public_id, type, resource_type, transformation, format, value)
      key = generate_cache_key(public_id, type, resource_type, transformation, format)
      Rails.cache.write(key, value)
    end

    def fetch(public_id, type, resource_type, transformation, format)
      key = generate_cache_key(public_id, type, resource_type, transformation, format)
      Rails.cache.fetch(key, &Proc.new)
    end
    private

    def generate_cache_key(public_id, type, resource_type, transformation, format)
      Digest::SHA1.hexdigest [public_id, type, resource_type, transformation, format].reject(&:blank?)
    end

  end
end