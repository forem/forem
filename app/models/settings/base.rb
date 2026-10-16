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

    # RequestStore flag that opts the current unit of work into reading the default subforem's settings
    # when there is no subforem context (see .resolve_read_subforem_id). Set by
    # Sidekiq::RequestStoreMiddleware for every job; never set during web requests.
    DEFAULT_SUBFOREM_FALLBACK_FLAG = :settings_fallback_to_default_subforem
    # RequestStore key memoizing the looked-up default subforem id (nil included) for the unit of work.
    DEFAULT_SUBFOREM_FALLBACK_ID = :settings_fallback_default_subforem_id

    after_commit :clear_cache, on: %i[create update destroy]

    class << self
      def clear_cache
        # Clear the main cache
        RequestStore.delete(cache_key)
        Rails.cache.delete(cache_key)

        # Clear any subforem-specific caches
        Subforem.find_each do |subforem|
          subforem_cache_key = "#{cache_key}-#{subforem.id}"
          RequestStore.delete(subforem_cache_key)
          Rails.cache.delete(subforem_cache_key)
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

        # Getter that supports passing subforem_id or falling back to the current subforem context
        # (see resolve_read_subforem_id)
        define_singleton_method(key) do |subforem_id: nil|
          subforem_id = __send__(:resolve_read_subforem_id, subforem_id)
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

      # Resolves which subforem a read applies to:
      #   1. an explicit subforem_id argument
      #   2. the web request's subforem (Middlewares::SetSubforem)
      #   3. the web request's default subforem (Middlewares::SetSubforem)
      #   4. only when DEFAULT_SUBFOREM_FALLBACK_FLAG is set (Sidekiq jobs): the default subforem
      #
      # Admin edits made through the web UI are saved on the default subforem's rows. Without (4), a
      # Sidekiq job has no request context and reads only global (subforem_id: nil) rows, so it silently
      # misses those edits (e.g. spam trigger terms, internal content description spec). With (4), a job
      # reads exactly what a web request on the default subforem reads: its rows first, then global rows.
      #
      # (4) is deliberately opt-in so web requests (including middleware that runs before SetSubforem,
      # such as Middlewares::SetCookieDomain), the console and rake keep their existing behavior.
      # Setters do not use this: a write without a subforem still goes to the global row.
      def resolve_read_subforem_id(subforem_id)
        subforem_id ||
          RequestStore.store[:subforem_id] ||
          RequestStore.store[:default_subforem_id] ||
          fallback_default_subforem_id
      end

      def fallback_default_subforem_id
        return unless RequestStore.store[DEFAULT_SUBFOREM_FALLBACK_FLAG]

        # Hash#fetch so a nil result (a forem without subforems) is memoized too, and
        # Subforem.cached_default_id doesn't hit the database on every read.
        RequestStore.store.fetch(DEFAULT_SUBFOREM_FALLBACK_ID) do
          RequestStore.store[DEFAULT_SUBFOREM_FALLBACK_ID] = Subforem.cached_default_id
        end
      end

      def value_of(var_name, subforem_id = nil)
        subforem_id = resolve_read_subforem_id(subforem_id)
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
