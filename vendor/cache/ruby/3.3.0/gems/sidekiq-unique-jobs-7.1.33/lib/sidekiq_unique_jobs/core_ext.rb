# frozen_string_literal: true

# :nocov:

#
# Monkey patches for the ruby Hash
#
class Hash
  unless {}.respond_to?(:slice)
    #
    # Returns only the matching keys in a new hash
    #
    # @param [Array<String>, Array<Symbol>] keys the keys to match
    #
    # @return [Hash]
    #
    def slice(*keys)
      keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
      keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if key?(k) }
    end
  end

  unless {}.respond_to?(:deep_stringify_keys)
    #
    # Depp converts all keys to string
    #
    #
    # @return [Hash<String>]
    #
    def deep_stringify_keys
      deep_transform_keys(&:to_s)
    end
  end

  unless {}.respond_to?(:deep_transform_keys)
    #
    # Deep transfor all keys by yielding to the caller
    #
    #
    # @return [Hash<String>]
    #
    def deep_transform_keys(&block)
      _deep_transform_keys_in_object(self, &block)
    end
  end

  unless {}.respond_to?(:stringify_keys)
    #
    # Converts all keys to string
    #
    #
    # @return [Hash<String>]
    #
    def stringify_keys
      transform_keys(&:to_s)
    end
  end

  unless {}.respond_to?(:transform_keys)
    #
    # Transforms all keys by yielding to the caller
    #
    #
    # @return [Hash]
    #
    def transform_keys
      result = {}
      each_key do |key|
        result[yield(key)] = self[key]
      end
      result
    end
  end

  unless {}.respond_to?(:slice!)
    #
    # Removes all keys not provided from the current hash and returns it
    #
    # @param [Array<String>, Array<Symbol>] keys the keys to match
    #
    # @return [Hash]
    #
    def slice!(*keys)
      keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
      omit = slice(*self.keys - keys)
      hash = slice(*keys)
      hash.default      = default
      hash.default_proc = default_proc if default_proc
      replace(hash)
      omit
    end
  end

  private

  unless {}.respond_to?(:_deep_transform_keys_in_object)
    # support methods for deep transforming nested hashes and arrays
    def _deep_transform_keys_in_object(object, &block)
      case object
      when Hash
        object.each_with_object(self.class.new) do |(key, value), result|
          result[yield(key)] = _deep_transform_keys_in_object(value, &block)
        end
      when Array
        object.map { |element| _deep_transform_keys_in_object(element, &block) }
      else
        object
      end
    end
  end
end

#
# Monkey patches for the ruby Array
#
class Array
  unless [].respond_to?(:extract_options!)
    #
    # Extract the last argument if it is a hash
    #
    #
    # @return [Hash]
    #
    def extract_options!
      if last.is_a?(Hash) && last.instance_of?(Hash)
        pop
      else
        {}
      end
    end
  end
end
