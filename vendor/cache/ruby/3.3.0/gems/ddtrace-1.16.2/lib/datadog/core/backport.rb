# frozen_string_literal: true

module Datadog
  module Core
    # This module is used to provide features from Ruby 2.5+ to older Rubies
    module BackportFrom25
      if ::String.method_defined?(:delete_prefix)
        def self.string_delete_prefix(string, prefix)
          string.delete_prefix(prefix)
        end
      else
        def self.string_delete_prefix(string, prefix)
          prefix = prefix.to_s
          if string.start_with?(prefix)
            string[prefix.length..-1] || raise('rbs-guard: String#[] is non-nil as `prefix` is guaranteed present')
          else
            string.dup
          end
        end
      end
    end

    # This module is used to provide features from Ruby 2.4+ to older Rubies
    module BackportFrom24
      if RUBY_VERSION < '2.4'
        def self.dup(value)
          case value
          when NilClass, TrueClass, FalseClass, Numeric
            value
          else
            value.dup
          end
        end
      else
        def self.dup(value)
          value.dup
        end
      end

      if ::Hash.method_defined?(:compact!)
        def self.hash_compact!(hash)
          hash.compact!
        end
      else
        def self.hash_compact!(hash)
          hash.reject! { |_key, value| value.nil? }
        end
      end
    end
  end
end
