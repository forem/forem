module Cloudinary
  module BaseConfig
    def load_from_url(url)
      return unless url && !url.empty?

      parsed_url = URI.parse(url)
      scheme = parsed_url.scheme.to_s.downcase

      if expected_scheme != scheme
        raise(CloudinaryException,
              "Invalid #{env_url} scheme. Expecting to start with '#{expected_scheme}://'")
      end

      update(config_from_parsed_url(parsed_url))
      setup_from_parsed_url(parsed_url)
    end

    def update(new_config = {})
      new_config.each{ |k,v| public_send(:"#{k}=", v) unless v.nil?}
    end

    def load_config_from_env
      raise NotImplementedError
    end

    private

    def config_from_parsed_url(parsed_url)
      raise NotImplementedError
    end

    def env_url
      raise NotImplementedError
    end

    def expected_scheme
      raise NotImplementedError
    end

    def put_nested_key(key, value)
      chain   = key.split(/[\[\]]+/).reject(&:empty?)
      outer   = self
      lastKey = chain.pop
      chain.each do |innerKey|
        inner = outer[innerKey]
        if inner.nil?
          inner           = OpenStruct.new
          outer[innerKey] = inner
        end
        outer = inner
      end
      outer[lastKey] = value
    end

    def is_nested_key?(key)
      /\w+\[\w+\]/ =~ key
    end

    def setup_from_parsed_url(parsed_url)
      parsed_url.query.to_s.split("&").each do |param|
        key, value = param.split("=")
        if is_nested_key? key
          put_nested_key key, value
        else
          update(key => Utils.smart_unescape(value))
        end
      end
    end
  end
end
