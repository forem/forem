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

      def to_h
        keys.to_h { |k| [k.to_sym, public_send(k)] }
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
        define_singleton_method(key) do |subforem_id: nil|
          result = __send__(:value_of, key, subforem_id)
          if result.nil? # fallback to default if no subforem-specific setting exists
            result ||= default.is_a?(Proc) ? default.call : default
          end
        
          read_as_type = type == :markdown ? :string : type
          result = __send__(:convert_string_to_value_type, read_as_type, result, separator: separator)
        
          result
        end

        # Explicit setter
          define_singleton_method(:"set_#{key}") do |value, subforem_id: nil|
          var_name = key

          record = find_by(var: var_name, subforem_id: subforem_id) || new(var: var_name, subforem_id: subforem_id)

          value = __send__(:convert_string_to_value_type, type, value, separator: separator)
          record.value = value
          record.save!

          value
        end

        # Alternative setting for current subforem (Fits pre-existing interface)
        define_singleton_method(:"#{key}=") do |value|
          var_name = key

          subforem_id = RequestStore.store[:subforem_id]

          record = find_by(var: var_name, subforem_id: subforem_id) || new(var: var_name, subforem_id: subforem_id)

          if type == :markdown
            processed = __send__(:convert_string_to_value_type, type, value)
            record.value = value
            record.save!
            __send__(:"#{key}_processed_html=", processed)
          else
            value = __send__(:convert_string_to_value_type, type, value, separator: separator)
            record.value = value
            record.save!
          end

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
        define_singleton_method(:"#{key}?") { __send__(key) }
      end

      def convert_string_to_value_type(type, value, separator: nil)
        return value unless value.class.in?([String, Integer, Float, BigDecimal])

        case type
        when :boolean
          value.in?(["true", "1", 1, true])
        when :array
          value.split(separator || SEPARATOR_REGEXP).compact_blank.map(&:strip)
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
        when :markdown
          ContentRenderer.new(value).process.processed_html
        else
          value
        end
      end

      def value_of(var_name, subforem_id = nil)
        subforem_id ||= (RequestStore.store[:subforem_id] || RequestStore.store[:default_subforem_id] || nil)
        unless table_exists?
          Rails.logger.warn("'#{table_name}' does not exist, '#{name}.#{var_name}' will return the default value.")
          return
        end
      
        if ActiveRecord::Base.connection.column_exists?(table_name, :subforem_id)
          record = unscoped
                     .where(var: var_name)
                     .where("subforem_id = ? OR subforem_id IS NULL", subforem_id)
                     .order(Arel.sql("CASE WHEN subforem_id IS NULL THEN 1 ELSE 0 END"))
                     .first
        else
          record = unscoped
                     .where(var: var_name)
                     .first
        end
      
        record&.value
      end

      def all_settings(var_name, subforem_id = nil)
        RequestStore[cache_key] ||= {}
        cache_key_with_subforem = "#{cache_key}-#{subforem_id}"
      
        RequestStore[cache_key_with_subforem] ||= Rails.cache.fetch(cache_key_with_subforem, expires_in: 1.week) do
          if subforem_id
            # Fetch settings for the specific subforem or fallback to global settings
            query = unscoped
                      .where(var: var_name)
                      .where(subforem_id: [subforem_id, nil])
                      .order(Arel.sql("CASE WHEN subforem_id IS NULL THEN 1 ELSE 0 END"))
          else
            # Fetch global settings only
            query = unscoped.where(var: var_name, subforem_id: nil)
          end
      
          query.each_with_object({}) do |record, result|
            result[record.var] = record.value
          end.with_indifferent_access
        end
      end
    end

    # get the setting's value, YAML decoded
    def value
      YAML.unsafe_load(self[:value]) if self[:value].present?
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
