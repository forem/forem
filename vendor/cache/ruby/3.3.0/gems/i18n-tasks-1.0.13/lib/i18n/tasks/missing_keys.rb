# frozen_string_literal: true

require 'set'
module I18n::Tasks
  module MissingKeys # rubocop:disable Metrics/ModuleLength
    MISSING_TYPES = %w[
      used
      diff
      plural
    ].freeze

    def self.missing_keys_types
      @missing_keys_types ||= MISSING_TYPES
    end

    def missing_keys_types
      MissingKeys.missing_keys_types
    end

    # @param types [:used, :diff, :plural] all if `nil`.
    # @return [Siblings]
    def missing_keys(locales: nil, types: nil, base_locale: nil)
      locales ||= self.locales
      types   ||= missing_keys_types
      base = base_locale || self.base_locale
      types.inject(empty_forest) do |f, type|
        f.merge! send(:"missing_#{type}_forest", locales, base)
      end
    end

    def eq_base_keys(opts = {})
      locales = Array(opts[:locales]).presence || self.locales
      (locales - [base_locale]).inject(empty_forest) do |tree, locale|
        tree.merge! equal_values_tree(locale, base_locale)
      end
    end

    def missing_diff_forest(locales, base = base_locale)
      tree = empty_forest
      # present in base but not locale
      (locales - [base]).each do |locale|
        tree.merge! missing_diff_tree(locale, base)
      end
      if locales.include?(base)
        # present in locale but not base
        (self.locales - [base]).each do |locale|
          tree.merge! missing_diff_tree(base, locale)
        end
      end
      tree
    end

    def missing_used_forest(locales, _base = base_locale)
      locales.inject(empty_forest) do |forest, locale|
        forest.merge! missing_used_tree(locale)
      end
    end

    def missing_plural_forest(locales, _base = base_locale)
      locales.each_with_object(empty_forest) do |locale, forest|
        required_keys = required_plural_keys_for_locale(locale)
        next if required_keys.empty?

        tree = empty_forest
        plural_nodes data[locale] do |node|
          children = node.children
          present_keys = Set.new(children.map { |c| c.key.to_sym })
          next if ignore_key?(node.full_key(root: false), :missing)
          next if present_keys.superset?(required_keys)

          tree[node.full_key] = node.derive(
            value: children.to_hash,
            children: nil,
            data: node.data.merge(missing_keys: (required_keys - present_keys).to_a)
          )
        end
        tree.set_root_key!(locale, type: :missing_plural)
        forest.merge!(tree)
      end
    end

    def required_plural_keys_for_locale(locale)
      @plural_keys_for_locale ||= {}
      return @plural_keys_for_locale[locale] if @plural_keys_for_locale.key?(locale)

      @plural_keys_for_locale[locale] = plural_keys_for_locale(locale)
    end

    # Loads rails-i18n pluralization config for the given locale.
    def load_rails_i18n_pluralization!(locale)
      path = File.join(Gem::Specification.find_by_name('rails-i18n').gem_dir, 'rails', 'pluralization', "#{locale}.rb")
      eval(File.read(path), binding, path) # rubocop:disable Security/Eval
    end

    # keys present in compared_to, but not in locale
    def missing_diff_tree(locale, compared_to = base_locale)
      data[compared_to].select_keys do |key, _node|
        locale_key_missing? locale, depluralize_key(key, compared_to)
      end.set_root_key!(locale, type: :missing_diff).keys do |_key, node|
        # change path and locale to base
        data = { locale: locale, missing_diff_locale: node.data[:locale] }
        if node.data.key?(:path)
          data[:path] = LocalePathname.replace_locale(node.data[:path], node.data[:locale], locale)
        end
        node.data.update data
      end
    end

    # keys used in the code missing translations in locale
    def missing_used_tree(locale)
      used_tree(strict: true).select_keys do |key, _node|
        locale_key_missing?(locale, key)
      end.set_root_key!(locale, type: :missing_used)
    end

    def equal_values_tree(locale, compare_to = base_locale)
      base = data[compare_to].first.children
      data[locale].select_keys(root: false) do |key, node|
        other_node = base[key]
        other_node && !node.reference? && node.value == other_node.value && !ignore_key?(key, :eq_base, locale)
      end.set_root_key!(locale, type: :eq_base)
    end

    def locale_key_missing?(locale, key)
      !key_value?(key, locale) && !external_key?(key, locale) && !ignore_key?(key, :missing)
    end

    # @param [::I18n::Tasks::Data::Tree::Siblings] forest
    # @yield [::I18n::Tasks::Data::Tree::Node]
    # @yieldreturn [Boolean] whether to collapse the node
    def collapse_same_key_in_locales!(forest)
      locales_and_node_by_key = {}
      to_remove               = []
      forest.each do |root|
        locale = root.key
        root.keys do |key, node|
          next unless yield node

          if locales_and_node_by_key.key?(key)
            locales_and_node_by_key[key][0] << locale
          else
            locales_and_node_by_key[key] = [[locale], node]
          end
          to_remove << node
        end
      end
      forest.remove_nodes_and_emptied_ancestors! to_remove
      locales_and_node_by_key.each_with_object({}) do |(key, (locales, node)), inv|
        (inv[locales.sort.join('+')] ||= []) << [key, node]
      end.map do |locales, keys_nodes|
        keys_nodes.each do |(key, node)|
          forest["#{locales}.#{key}"] = node
        end
      end
      forest
    end

    private

    def plural_keys_for_locale(locale)
      configuration = load_rails_i18n_pluralization!(locale)
      if configuration[locale.to_sym].nil?
        alternate_locale = alternate_locale_from(locale)
        return Set.new if configuration[alternate_locale.to_sym].nil?

        return set_from_rails_i18n_pluralization(configuration, alternate_locale)
      end
      set_from_rails_i18n_pluralization(configuration, locale)
    rescue SystemCallError, IOError
      Set.new
    end

    def alternate_locale_from(locale)
      re = /(\w{2})-*(\w{2,3})*/
      match = locale.match(re)
      language_code = match[1]
      country_code = match[2]
      "#{language_code}-#{country_code.upcase}"
    end

    def set_from_rails_i18n_pluralization(configuration, locale)
      Set.new(configuration[locale.to_sym][:i18n][:plural][:keys])
    end
  end
end
