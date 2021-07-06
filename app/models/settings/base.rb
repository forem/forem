# This was taken from the rails-settings-cached gem and adapted to work with
# more than one settings model by making the request cache class-specific. We
# also removed features we don't need like cache scopes and readonly fields.
#
# See: https://github.com/huacnlee/rails-settings-cached
module Settings
  class Base < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    self.abstract_class = true

    class SettingNotFound < RuntimeError; end

    class ProcetedKeyError < ArgumentError; end

    PROTECTED_KEYS = %w[var value].freeze
    SEPARATOR_REGEXP = /[\n,;]+/.freeze

    # In rails-settings-cache this is defined in the railtie.
    # See: https://github.com/huacnlee/rails-settings-cached/blob/main/lib/rails-settings/railtie.rb
    after_commit :clear_cache, on: %i[create update destroy]

    class << self
      def clear_cache
        RequestStore.delete(cache_key)
        Rails.cache.delete(cache_key)
      end

      def field(key, default: nil, type: :string, separator: nil, validates: nil)
        define_field(
          key,
          default: default,
          type: type,
          separator: separator,
          validates: validates,
        )
      end

      def get_field(key)
        @defined_fields.detect { |field| field[:key] == key.to_s } || {}
      end

      def keys
        @defined_fields.pluck(:key)
      end

      private

      def cache_key
        @cache_key ||= name.underscore
      end

      def define_field(key, default: nil, type: :string, separator: nil, validates: nil)
        key = key.to_s

        raise(ProcetedKeyError, "Can't use #{key} as setting key.") if key.in?(PROTECTED_KEYS)

        @defined_fields ||= []
        @defined_fields << {
          key: key,
          default: default,
          type: type || :string
        }

        # Getter
        define_singleton_method(key) do
          result = __send__(:value_of, key)
          result ||= default.is_a?(Proc) ? default.call : default
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

    # get the value field, YAML decoded
    def value
      YAML.load(self[:value]) if self[:value].present? # rubocop:disable Security/YAMLLoad
    end

    # set the value field, YAML encoded
    def value=(new_value)
      self[:value] = new_value.to_yaml
    end

    def clear_cache
      self.class.clear_cache
    end
  end
end
