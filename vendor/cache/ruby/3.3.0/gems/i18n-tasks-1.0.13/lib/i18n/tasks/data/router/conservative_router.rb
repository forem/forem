# frozen_string_literal: true

require 'i18n/tasks/data/router/pattern_router'

module I18n::Tasks
  module Data::Router
    # Keep the path, or infer from base locale
    class ConservativeRouter < PatternRouter
      def initialize(adapter, config)
        @adapter     = adapter
        @base_locale = config[:base_locale]
        @locales     = config[:locales]
        super
      end

      def route(locale, forest, &block) # rubocop:disable Metrics/AbcSize
        return to_enum(:route, locale, forest) unless block

        out = Hash.new { |hash, key| hash[key] = Set.new }
        not_found = Set.new
        forest.keys do |key, _node|
          path = key_path(locale, key)
          # infer from another locale
          unless path
            inferred_from = (locales - [locale]).detect { |loc| path = key_path(loc, key) }
            path = LocalePathname.replace_locale(path, inferred_from, locale) if inferred_from
          end
          key_with_locale = "#{locale}.#{key}"
          if path
            out[path] << key_with_locale
          else
            not_found << key_with_locale
          end
        end

        if not_found.present?
          # fall back to pattern router
          not_found_tree = forest.select_keys(root: true) { |key, _| not_found.include?(key) }
          super(locale, not_found_tree) do |path, tree|
            out[path] += tree.key_names(root: true)
          end
        end

        out.each do |dest, keys|
          block.yield dest, forest.select_keys(root: true) { |key, _| keys.include?(key) }
        end
      end

      protected

      def base_tree
        adapter[base_locale]
      end

      def key_path(locale, key)
        adapter[locale]["#{locale}.#{key}"].try(:data).try(:[], :path)
      end

      attr_reader :adapter, :base_locale, :locales
    end
  end
end
