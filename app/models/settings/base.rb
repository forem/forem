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
        # Clear the main cache
        RequestStore.delete(cache_key)
        Rails.cache.delete(cache_key)

        # Clear any subforem-specific caches
        RequestStore.keys.each do |k|
          if k.to_s.start_with?("#{cache_key}-")
            RequestStore.delete(k)
            Rails.cache.delete(k)
          end
        end
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

      def to_h(subforem_id: nil)
        keys.to_h { |k| [k.to_sym, public_send(k, subforem_id: subforem_id)] }
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

        # Getter that supports passing subforem_id or falling back to RequestStore
        define_singleton_method(key) do |subforem_id: nil|
          # Fall back to the currently set subforem_id in the request if none provided
          subforem_id ||= (RequestStore.store[:subforem_id] || RequestStore.store[:default_subforem_id] || nil)
          result = __send__(:value_of, key, subforem_id)

          if result.nil?
            result = default.is_a?(Proc) ? default.call : default
          end

          read_as_type = type == :markdown ? :string : type
          __send__(:convert_string_to_value_type, read_as_type, result, separator: separator)
        end

        # Explicit setter that takes a subforem_id as an argument
        define_singleton_method(:"set_#{key}") do |value, subforem_id: nil|
          subforem_id ||= (RequestStore.store[:subforem_id] || RequestStore.store[:default_subforem_id] || nil)
          var_name = key

          record = find_by(var: var_name, subforem_id: subforem_id) || new(var: var_name, subforem_id: subforem_id)

          if type == :markdown
            processed = __send__(:convert_string_to_value_type, type, value)
            record.value = value
            record.save!
            __send__(:"#{key}_processed_html=", processed)
          else
            converted_value = __send__(:convert_string_to_value_type, type, value, separator: separator)
            record.value = converted_value
            record.save!
          end

          clear_cache
          value
        end

        # Setter that uses the request’s current subforem_id implicitly
        define_singleton_method(:"#{key}=") do |value|
          var_name = key
          subforem_id = RequestStore.store[:subforem_id] || RequestStore.store[:default_subforem_id]

          record = find_by(var: var_name, subforem_id: subforem_id) || new(var: var_name, subforem_id: subforem_id)

          if type == :markdown
            processed = __send__(:convert_string_to_value_type, type, value)
            record.value = value
            record.save!
            __send__(:"#{key}_processed_html=", processed)
          else
            converted_value = __send__(:convert_string_to_value_type, type, value, separator: separator)
            record.value = converted_value
            record.save!
          end

          clear_cache
          value
        end

        # Validation
        if validates
          validates[:if] = proc { |item| item.var.to_s == key }
          __send__(:validates, key, **validates)

          define_method(:read_attribute_for_validation) { |_attr_key| self.value }
        end

        return unless type == :boolean

        # Predicate method for booleans
        define_singleton_method(:"#{key}?") { public_send(key) }
      end

      def convert_string_to_value_type(type, value, separator: nil)
        return value unless value.is_a?(String) || value.is_a?(Integer) || value.is_a?(Float) || value.is_a?(BigDecimal)

        case type
        when :boolean
          value.in?(["true", "1", 1, true])
        when :array
          value.to_s.split(separator || SEPARATOR_REGEXP).compact_blank.map(&:strip)
        when :hash
          val = begin
            YAML.safe_load(value.to_s).to_h
          rescue StandardError
            {}
          end
          val.deep_stringify_keys!
          ActiveSupport::HashWithIndifferentAccess.new(val)
        when :integer
          value.to_i
        when :float
          value.to_f
        when :big_decimal
          value.to_d
        when :markdown
          ContentRenderer.new(value.to_s).process.processed_html
        else
          value
        end
      end

      def value_of(var_name, subforem_id = nil)
        # Ensure we fallback to the request store if not provided
        subforem_id ||= (RequestStore.store[:subforem_id] || RequestStore.store[:default_subforem_id] || nil)
        all = all_settings(subforem_id)
        all[var_name]
      end

      def all_settings(subforem_id = nil)
        # Use a subforem-specific cache key if we have a subforem_id
        cache_key_with_subforem = subforem_id.present? ? "#{cache_key}-#{subforem_id}" : cache_key

        RequestStore[cache_key_with_subforem] ||= Rails.cache.fetch(cache_key_with_subforem, expires_in: 1.week) do
          unless table_exists?
            # If table doesn't exist yet, return an empty hash
            {}
          else
            # If subforem_id is given, fetch both subforem-specific and global (nil) settings
            # Ordering ensures subforem-specific appear first and set the var in the hash
            query = if subforem_id
                      unscoped
                        .select(:var, :value, :subforem_id)
                        .where(subforem_id: [subforem_id, nil])
                        .order(Arel.sql("CASE WHEN subforem_id IS NULL THEN 1 ELSE 0 END"))
                    else
                      # No subforem_id means only global settings (subforem_id = nil)
                      unscoped.select(:var, :value).where(subforem_id: nil)
                    end

            result = {}
            query.each do |record|
              # The first time we set a var will be the subforem-specific row if it exists,
              # else the global one will remain.
              result[record.var] ||= record.value
            end
            result.with_indifferent_access
          end
        end
      end
    end

    def value
      YAML.unsafe_load(self[:value]) if self[:value].present?
    end

    def value=(new_value)
      self[:value] = new_value.to_yaml
    end

    def clear_cache
      self.class.clear_cache
    end
  end
end
