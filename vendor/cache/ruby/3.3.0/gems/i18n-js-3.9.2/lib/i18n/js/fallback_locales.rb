module I18n
  module JS
    class FallbackLocales
      attr_reader :fallbacks, :locale

      def initialize(fallbacks, locale)
        @fallbacks = fallbacks
        @locale = locale
      end

      def each
        locales.each { |locale| yield(locale) }
      end

      # @return [Array<String, Symbol>]
      #   An Array of locales to use as fallbacks for given locale.
      def locales
        locales = case fallbacks
                  when true
                    default_fallbacks
                  when :default_locale
                    [::I18n.default_locale]
                  when Symbol, String
                    [fallbacks.to_sym]
                  when Array
                    ensure_valid_fallbacks_as_array!
                    fallbacks
                  when Hash
                    Array(fallbacks[locale] || default_fallbacks)
                  else
                    fail ArgumentError, "fallbacks must be: true, :default_locale an Array or a Hash - given: #{fallbacks}"
                  end

        locales.map! { |locale| locale.to_sym }
        locales
      end

      private

      # @return [Array<String, Symbol>] An Array of locales.
      def default_fallbacks
        if using_i18n_fallbacks_module?
          I18n.fallbacks[locale]
        else
          [::I18n.default_locale]
        end
      end

      # @return
      #   true if we can safely use I18n.fallbacks, false otherwise.
      #
      # @note
      #   We should implement this as `I18n.respond_to?(:fallbacks)`, but
      #   once I18n::Backend::Fallbacks is included, I18n will _always_
      #   respond to :fallbacks. Even if we switch the backend to one
      #   without fallbacks!
      #
      #   Maybe this should be fixed within I18n.
      def using_i18n_fallbacks_module?
        I18n::JS.backend.class.included_modules.include?(I18n::Backend::Fallbacks)
      end

      def ensure_valid_fallbacks_as_array!
        return if fallbacks.all? { |e| e.is_a?(String) || e.is_a?(Symbol) }

        fail ArgumentError, "If fallbacks is passed as Array, it must ony include Strings or Symbols. Given: #{fallbacks}"
      end
    end
  end
end
