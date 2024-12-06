# frozen_string_literal: true

module I18n::Tasks::Reports
  class Base
    include I18n::Tasks::Logging

    def initialize(task = I18n::Tasks::BaseTask.new)
      @task = task
    end

    attr_reader :task

    delegate :base_locale, :locales, to: :task

    protected

    def missing_type_info(type)
      ::I18n::Tasks::MissingKeys::MISSING_TYPES[type.to_s.sub(/\Amissing_/, '').to_sym]
    end

    def missing_title(forest)
      "Missing translations (#{forest.leaves.count || '∅'})"
    end

    def inconsistent_interpolations_title(forest)
      "Inconsistent interpolations (#{forest.leaves.count || '∅'})"
    end

    def unused_title(key_values)
      "Unused keys (#{key_values.count || '∅'})"
    end

    def eq_base_title(key_values, locale = base_locale)
      "Same value as #{locale} (#{key_values.count || '∅'})"
    end

    def used_title(keys_nodes, filter)
      used_n = keys_nodes.map { |_k, node| node.data[:occurrences].size }.reduce(:+).to_i
      "#{keys_nodes.size} key#{'s' if keys_nodes.size != 1}#{" matching '#{filter}'" if filter}" \
        "#{" (#{used_n} usage#{'s' if used_n != 1})" if used_n.positive?}"
    end

    # Sort keys by their attributes in order
    # @param [Hash] order e.g. {locale: :asc, type: :desc, key: :asc}
    def sort_by_attr!(objects, order = { locale: :asc, key: :asc })
      order_keys = order.keys
      objects.sort! do |a, b|
        by = order_keys.detect { |k| a[k] != b[k] }
        order[by] == :desc ? b[by] <=> a[by] : a[by] <=> b[by]
      end
      objects
    end

    def forest_to_attr(forest)
      forest.keys(root: false).map do |key, node|
        { key: key, value: node.value, type: node.data[:type], locale: node.root.key, data: node.data }
      end
    end

    def format_locale(locale)
      return '' unless locale

      if locale.split('+') == task.locales.sort
        'all'
      else
        locale.tr '+', ' '
      end
    end

    def collapse_missing_tree!(forest)
      forest = task.collapse_plural_nodes!(forest)
      task.collapse_same_key_in_locales!(forest) { |node| node.data[:type] == :missing_used }
    end
  end
end
