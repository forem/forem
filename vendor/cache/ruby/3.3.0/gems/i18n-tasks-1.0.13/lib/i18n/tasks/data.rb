# frozen_string_literal: true

require 'i18n/tasks/data/file_system'

module I18n::Tasks
  module Data
    DATA_DEFAULTS = {
      adapter: 'I18n::Tasks::Data::FileSystem'
    }.freeze

    # I18n data provider
    # @see I18n::Tasks::Data::FileSystem
    def data
      @data ||= begin
        data_config = (config[:data] || {}).deep_symbolize_keys
        data_config[:base_locale] = base_locale
        data_config[:locales] = config[:locales]
        adapter_class = data_config[:adapter].presence || data_config[:class].presence || DATA_DEFAULTS[:adapter]
        adapter_class = adapter_class.to_s
        adapter_class = 'I18n::Tasks::Data::FileSystem' if adapter_class == 'file_system'
        data_config.except!(:adapter, :class)
        ActiveSupport::Inflector.constantize(adapter_class).new data_config
      end
    end

    def empty_forest
      ::I18n::Tasks::Data::Tree::Siblings.new
    end

    def data_forest(locales = self.locales)
      locales.inject(empty_forest) do |tree, locale|
        tree.merge! data[locale]
      end
    end

    def t(key, locale = base_locale)
      data.t(key, locale)
    end

    def tree(sel)
      data[split_key(sel, 2).first][sel].try(:children)
    end

    def node(key, locale = base_locale)
      data[locale]["#{locale}.#{key}"]
    end

    def build_tree(hash)
      I18n::Tasks::Data::Tree::Siblings.from_nested_hash(hash)
    end

    def t_proc(locale = base_locale)
      @t_proc         ||= {}
      @t_proc[locale] ||= proc { |key| t(key, locale) }
    end

    # whether the value for key exists in locale (defaults: base_locale)
    def key_value?(key, locale = base_locale)
      !t(key, locale).nil?
    end

    def external_key?(key, locale = base_locale)
      data.external(locale)[locale.to_s][key]
    end

    # Normalize all the locale data in the store (by writing to the store).
    #
    # @param [Array<String>] locales locales to normalize. Default: all.
    # @param [Boolean] force_pattern_router Whether to use pattern router regardless of the config.
    def normalize_store!(locales: nil, force_pattern_router: false)
      locales ||= self.locales
      router = force_pattern_router ? ::I18n::Tasks::Data::Router::PatternRouter.new(data, data.config) : data.router
      data.with_router(router) do
        Array(locales).each do |target_locale|
          # The store handles actual normalization:
          data[target_locale] = data[target_locale]
        end
      end
    end

    # @param [Array<String>] locales locales to check. Default: all.
    # @return [Array<String>] paths to data that requires normalization
    def non_normalized_paths(locales: nil)
      Array(locales || self.locales).flat_map { |locale| data.non_normalized_paths(locale) }
    end
  end
end
