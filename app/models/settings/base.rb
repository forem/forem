# This class was adapted from the rails-settings-cached gem.
# See: https://github.com/huacnlee/rails-settings-cached
#
# It has changed in several significant ways:
#   * renamed DSL method from "field" to "setting"
#   * refactored request caching to allow for more than one settings model
#   * removed features like cache prefixes and readonly fields
#   * changed code in accordance with Rubocop and our internal practices
module Settings
  class ProtectedKeyError < ArgumentError; end

  class Base < ApplicationRecord
    self.abstract_class = true

    PROTECTED_KEYS = %w[var value].freeze
    SEPARATOR_REGEXP = /[\n,;]+/

    after_commit :clear_cache, on: %i[create update destroy]

    class << self
      def clear_cache
        RequestStore.delete(cache_key)
        Rails.cache.delete(cache_key)
      end

      def setting(key, default: nil, type: :string, separator: nil, validates: nil)
        define_setting(
          key,
          default: default,
          type: type,
          separator: separator,
          validates: validates,
        )
      end

      def get_setting(key)
        @defined_settings.detect { |setting| setting[:key] == key.to_s } || {}
      end

      def get_default(key)
        get_setting(key)[:default]
      end

      def keys
        @defined_settings.pluck(:key)
      end

      private

      def cache_key
        @cache_key ||= name.underscore
      end

      def define_setting(key, default: nil, type: :string, separator: nil, validates: nil)
        key = key.to_s

        raise(ProtectedKeyError, "Can't use '#{key}' as setting name") if key.in?(PROTECTED_KEYS)

        @defined_settings ||= []
        @defined_settings << {
          key: key,
          default: default,
          type: type || :string
        }

        # Getter
        define_singleton_method(key) do
          result = __send__(:value_of, key)
          if result.nil? # we don't want to accidentally do this for "false"
            result ||= default.is_a?(Proc) ? default.call : default
          end
          result = __send__(:convert_string_to_value_type, type, result, separator: separator)

          result
        end

        # Setter
        define_singleton_method("#{key}=") do |value|
          var_name = key

          record = find_by(var: var_name) || new(var: var_name)
          value = __send__(:convert_string_to_value_type, type, value, separator: separator)

          record.value = value
          record.save!

          value
        end

        # Validation
        if validates
          validates[:if] = proc { |item| item.var.to_s == key }
          __send__(:validates, key, **validates)

          define_method(:read_attribute_for_validation) { |_key| self.value }
        end

        return unless type == :boolean

        # Predicate method for booleans
        define_singleton_method("#{key}?") { __send__(key) }
      end

      def convert_string_to_value_type(type, value, separator: nil)
        return value unless value.class.in?([String, Integer, Float, BigDecimal])

        case type
        when :boolean
          value.in?(["true", "1", 1, true])
        when :array
          value.split(separator || SEPARATOR_REGEXP).reject(&:empty?).map(&:strip)
        when :hash
          value = begin
            YAML.safe_load(value).to_h
          rescue StandardError
            {}
          end
          value.deep_stringify_keys!
          ActiveSupport::HashWithIndifferentAccess.new(value)
        when :integer
          value.to_i
        when :float
          value.to_f
        when :big_decimal
          value.to_d
        else
          value
        end
      end

      def value_of(var_name)
        unless Database.table_available?(table_name)
          # Fallback to default value if table was not ready (before migrate)
          Rails.logger.warn("'#{table_name}' does not exist, '#{name}.#{var_name}' will return the default value.")
          return
        end

        all_settings[var_name]
      end

      def all_settings
        RequestStore[cache_key] ||= Rails.cache.fetch(cache_key, expires_in: 1.week) do
          unscoped.select(:var, :value).each_with_object({}) do |record, result|
            result[record.var] = record.value
          end.with_indifferent_access
        end
      end
    end

    # get the setting's value, YAML decoded
    def value
      YAML.load(self[:value]) if self[:value].present? # rubocop:disable Security/YAMLLoad
    end

    # set the settings's value, YAML encoded
    def value=(new_value)
      self[:value] = new_value.to_yaml
    end

    def clear_cache
      self.class.clear_cache
    end
  end
end
