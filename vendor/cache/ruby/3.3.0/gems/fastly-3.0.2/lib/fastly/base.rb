class Fastly
  # Base class for all Fastly objects
  class Base # :nodoc: all
    attr_accessor :fetcher

    def initialize(opts, fetcher)
      @keys = []
      opts.each do |key, val|
        next unless self.respond_to? "#{key}="
        send("#{key}=", val)
        @keys.push(key)
      end
      self.fetcher = fetcher
    end

    # Save this object
    def save!
      fetcher.update(self.class, self)
    end

    # Delete this object
    def delete!
      fetcher.delete(self.class, self)
    end

    ##
    # :nodoc:
    def as_hash
      ret = {}
      @keys.each do |key|
        ret[key] = send("#{key}") unless key =~ /^_/
      end
      ret
    end

    def require_api_key!
      fetcher.client.require_key!
    end

    def self.path
      Util.class_to_path(self)
    end

    def self.get_path(id)
      "/#{path}/#{id}"
    end

    def self.post_path(_opts = {})
      "/#{path}"
    end

    def self.list_path(opts = {})
      post_path(opts)
    end

    def self.put_path(object)
      get_path(object.id)
    end

    def self.delete_path(object)
      put_path(object)
    end
  end
end
