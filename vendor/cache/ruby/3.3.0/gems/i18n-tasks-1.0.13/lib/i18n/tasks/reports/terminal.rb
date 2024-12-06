# frozen_string_literal: true

require 'i18n/tasks/reports/base'
require 'terminal-table'
module I18n
  module Tasks
    module Reports
      class Terminal < Base # rubocop:disable Metrics/ClassLength
        def missing_keys(forest = task.missing_keys)
          forest = collapse_missing_tree! forest
          if forest.present?
            print_title missing_title(forest)
            print_table headings: [Rainbow(I18n.t('i18n_tasks.common.locale')).cyan.bright,
                                   Rainbow(I18n.t('i18n_tasks.common.key')).cyan.bright,
                                   I18n.t('i18n_tasks.missing.details_title')] do |t|
              t.rows = sort_by_attr!(forest_to_attr(forest)).map do |a|
                [{ value: Rainbow(format_locale(a[:locale])).cyan, alignment: :center },
                 format_key(a[:key], a[:data]),
                 missing_key_info(a)]
              end
            end
          else
            print_success I18n.t('i18n_tasks.missing.none')
          end
        end

        def inconsistent_interpolations(forest = task.inconsistent_interpolations)
          if forest.present?
            print_title inconsistent_interpolations_title(forest)
            show_tree(forest)
          else
            print_success I18n.t('i18n_tasks.inconsistent_interpolations.none')
          end
        end

        def used_keys(used_tree = task.used_tree)
          # For the used tree we may have usage nodes that are not leaves as references.
          keys_nodes = used_tree.nodes.select { |node| node.data[:occurrences].present? }.map do |node|
            [node.full_key(root: false), node]
          end
          print_title used_title(keys_nodes, used_tree.first.root.data[:key_filter])
          # Group multiple nodes
          if keys_nodes.present?
            keys_nodes.sort! { |a, b| a[0] <=> b[0] }.each do |key, node|
              print_occurrences node, key
            end
          else
            print_error I18n.t('i18n_tasks.usages.none')
          end
        end

        def unused_keys(tree = task.unused_keys)
          keys = tree.root_key_value_data(true)
          if keys.present?
            print_title unused_title(keys)
            print_locale_key_value_data_table keys
          else
            print_success I18n.t('i18n_tasks.unused.none')
          end
        end

        def eq_base_keys(tree = task.eq_base_keys)
          keys = tree.root_key_value_data(true)
          if keys.present?
            print_title eq_base_title(keys)
            print_locale_key_value_data_table keys
          else
            print_info Rainbow('No translations are the same as base value').cyan
          end
        end

        def show_tree(tree)
          print_locale_key_value_data_table tree.root_key_value_data(true)
        end

        def forest_stats(forest, stats = task.forest_stats(forest))
          text  = if stats[:locale_count] == 1
                    I18n.t('i18n_tasks.data_stats.text_single_locale', **stats)
                  else
                    I18n.t('i18n_tasks.data_stats.text', **stats)
                  end
          title = Rainbow(I18n.t('i18n_tasks.data_stats.title', **stats.slice(:locales))).bright
          print_info "#{Rainbow(title).cyan} #{Rainbow(text).cyan}"
        end

        def mv_results(results)
          results.each do |(from, to)|
            if to
              print_info "#{Rainbow(from).cyan} #{Rainbow('⮕').yellow.bright} #{Rainbow(to).cyan}"
            else
              print_info "#{Rainbow(from).red}#{Rainbow(' 🗑').red.bright}"
            end
          end
        end

        def check_normalized_results(non_normalized)
          if non_normalized.empty?
            print_success 'All data is normalized'
            return
          end
          log_stderr Rainbow('The following data requires normalization:').yellow
          puts non_normalized
          log_stderr Rainbow('Run `i18n-tasks normalize` to fix').yellow
        end

        private

        def missing_key_info(leaf)
          case leaf[:type]
          when :missing_used
            first_occurrence leaf
          when :missing_plural
            leaf[:data][:missing_keys].join(', ')
          else
            "#{Rainbow(leaf[:data][:missing_diff_locale]).cyan} " \
            "#{format_value(leaf[:value].is_a?(String) ? leaf[:value].strip : leaf[:value])}"
          end
        end

        def format_key(key, data)
          if data[:ref_info]
            from, to = data[:ref_info]
            resolved = key[0...to.length]
            after    = key[to.length..]
            "  #{Rainbow(from).yellow}#{Rainbow(after).cyan}\n" \
              "#{Rainbow('⮕').yellow.bright} #{Rainbow(resolved).yellow.bright}"
          else
            Rainbow(key).cyan
          end
        end

        def format_value(val)
          val.is_a?(Symbol) ? "#{Rainbow('⮕ ').yellow.bright}#{Rainbow(val).yellow}" : val.to_s.strip
        end

        def format_reference_desc(node_data)
          return nil unless node_data

          case node_data[:ref_type]
          when :reference_usage
            Rainbow('(ref)').yellow.bright
          when :reference_usage_resolved
            Rainbow('(resolved ref)').yellow.bright
          when :reference_usage_key
            Rainbow('(ref key)').yellow.bright
          end
        end

        def print_occurrences(node, full_key = node.full_key)
          occurrences = node.data[:occurrences]
          puts [Rainbow(full_key).bright,
                format_reference_desc(node.data),
                (Rainbow(occurrences.size).green if occurrences.size > 1)].compact.join ' '
          occurrences.each do |occurrence|
            puts "  #{key_occurrence full_key, occurrence}"
          end
        end

        def print_locale_key_value_data_table(locale_key_value_datas)
          if locale_key_value_datas.present?
            print_table headings: [Rainbow(I18n.t('i18n_tasks.common.locale')).cyan.bright,
                                   Rainbow(I18n.t('i18n_tasks.common.key')).cyan.bright,
                                   I18n.t('i18n_tasks.common.value')] do |t|
              t.rows = locale_key_value_datas.map do |(locale, k, v, data)|
                [{ value: Rainbow(locale).cyan, alignment: :center }, format_key(k, data), format_value(v)]
              end
            end
          else
            puts 'ø'
          end
        end

        def print_title(title)
          log_stderr "#{Rainbow(title.strip).bright} #{Rainbow('|').faint} " \
                     "#{"i18n-tasks v#{I18n::Tasks::VERSION}"}"
        end

        def print_success(message)
          log_stderr Rainbow("✓ #{I18n.t('i18n_tasks.cmd.encourage').sample} #{message}").green.bright
        end

        def print_error(message)
          log_stderr(Rainbow(message).red.bright)
        end

        def print_info(message)
          log_stderr message
        end

        def indent(txt, n = 2)
          txt.gsub(/^/, ' ' * n)
        end

        def print_table(opts, &block)
          puts ::Terminal::Table.new(opts, &block)
        end

        def key_occurrence(full_key, occurrence)
          location = Rainbow("#{occurrence.path}:#{occurrence.line_num}").green
          source   = highlight_key(occurrence.raw_key || full_key, occurrence.line, occurrence.line_pos..-1).strip
          "#{location} #{source}"
        end

        def first_occurrence(leaf)
          # @type [I18n::Tasks::Scanners::KeyOccurrences]
          occurrences = leaf[:data][:occurrences]
          # @type [I18n::Tasks::Scanners::Occurrence]
          first = occurrences.first
          [
            Rainbow("#{first.path}:#{first.line_num}").green,
            ("(#{I18n.t 'i18n_tasks.common.n_more', count: occurrences.length - 1})" if occurrences.length > 1)
          ].compact.join(' ')
        end

        def highlight_key(full_key, line, range = (0..-1))
          line.dup.tap do |s|
            s[range] = s[range].sub(full_key) do |m|
              highlight_string m
            end
          end
        end

        module HighlightUnderline
          def highlight_string(s)
            Rainbow(s).underline
          end
        end

        module HighlightOther
          def highlight_string(s)
            Rainbow(s).yellow
          end
        end

        if Gem.win_platform?
          include HighlightOther
        else
          include HighlightUnderline
        end
      end
    end
  end
end
