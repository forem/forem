# frozen_string_literal: true

require 'set'

module I18n
  module Tasks
    module UnusedKeys
      def unused_keys(locales: nil, strict: nil)
        locales = Array(locales).presence || self.locales
        locales.map { |locale| unused_tree(locale: locale, strict: strict) }.compact.reduce(:merge!)
      end

      # @param [String] locale
      # @param [Boolean] strict if true, do not match dynamic keys
      def unused_tree(locale: base_locale, strict: nil)
        used_key_names = used_tree(strict: true).key_names
        collapse_plural_nodes!(data[locale].select_keys do |key, _node|
          !ignore_key?(key, :unused) &&
            (strict || !used_in_expr?(key)) &&
            !used_key_names.include?(depluralize_key(key, locale))
        end)
      end
    end
  end
end
