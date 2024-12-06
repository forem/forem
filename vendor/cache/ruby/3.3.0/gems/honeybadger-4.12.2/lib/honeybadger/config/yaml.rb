require 'pathname'
require 'yaml'
require 'erb'

module Honeybadger
  class Config
    module Yaml
      DISALLOWED_KEYS = [:'config.path'].freeze

      def self.new(path, env = 'production')
        path = path.kind_of?(Pathname) ? path : Pathname.new(path)

        if !path.exist?
          raise ConfigError, "The configuration file #{path} was not found."
        elsif !path.file?
          raise ConfigError, "The configuration file #{path} is not a file."
        elsif !path.readable?
          raise ConfigError, "The configuration file #{path} is not readable."
        end

        yaml = load_yaml(path)
        yaml.merge!(yaml[env]) if yaml[env].kind_of?(Hash)

        dotify_keys(yaml)
      end

      def self.load_yaml(path)
        begin
          # This uses `YAML.unsafe_load` to support loading arbitrary Ruby
          # classes, such as !ruby/regexp. This was the default behavior prior
          # to Psych 4. https://bugs.ruby-lang.org/issues/17866
          method = YAML.respond_to?(:unsafe_load) ? :unsafe_load : :load
          yaml = YAML.send(method, ERB.new(path.read).result)
        rescue => e
          config_error = ConfigError.new(e.to_s)

          if e.backtrace
            backtrace = e.backtrace.map do |line|
              if line.start_with?('(erb)'.freeze)
                line.gsub('(erb)'.freeze, path.to_s)
              else
                line
              end
            end
            config_error.set_backtrace(backtrace)
          end

          raise config_error
        end

        case yaml
        when Hash
          yaml
        when NilClass, FalseClass
          {}
        else
          raise ConfigError, "The configuration file #{path} is invalid."
        end
      end

      def self.dotify_keys(hash, key_prefix = nil)
        {}.tap do |new_hash|
          hash.each_pair do |k,v|
            k = [key_prefix, k].compact.join('.')
            if v.kind_of?(Hash)
              new_hash.update(dotify_keys(v, k))
            else
              next if DISALLOWED_KEYS.include?(k.to_sym)
              new_hash[k.to_sym] = v
            end
          end
        end
      end
    end
  end
end
