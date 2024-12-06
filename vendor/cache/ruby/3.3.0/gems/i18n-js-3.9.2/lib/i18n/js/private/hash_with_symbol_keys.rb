module I18n
  module JS
    # @api private
    module Private
      # Hash with string keys converted to symbol keys
      # Used for handling values read on YAML
      #
      # @api private
      class HashWithSymbolKeys < ::Hash
        # An instance can only be created by passing in another hash
        def initialize(hash)
          raise TypeError unless hash.is_a?(::Hash)

          hash.each_key do |key|
            # Objects like `Integer` does not have `to_sym`
            new_key = key.respond_to?(:to_sym) ? key.to_sym : key
            self[new_key] = hash[key]
          end

          self.default = hash.default if hash.default
          self.default_proc = hash.default_proc if hash.default_proc

          freeze
        end

        # From AS Core extension
        def slice(*keys)
          hash = keys.each_with_object(Hash.new) do |k, hash|
            hash[k] = self[k] if has_key?(k)
          end
          self.class.new(hash)
        end
      end
    end
  end
end
