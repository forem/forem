# frozen_string_literal: true

module I18n::Tasks
  module Command
    module Commands
      module Usages
        include Command::Collection

        arg :strict,
            '--[no-]strict',
            t('i18n_tasks.cmd.args.desc.strict')

        arg :keep_order,
            '-k',
            '--keep-order',
            t('i18n_tasks.cmd.args.desc.keep_order')

        cmd :find,
            pos: '[pattern]',
            desc: t('i18n_tasks.cmd.desc.find'),
            args: %i[out_format pattern strict]

        def find(opt = {})
          opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
          result = i18n.used_tree(strict: opt[:strict], key_filter: opt[:filter].presence, include_raw_references: true)
          print_forest result, opt, :used_keys
        end

        cmd :unused,
            pos: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.unused'),
            args: %i[locales out_format strict]

        def unused(opt = {})
          forest = i18n.unused_keys(**opt.slice(:locales, :strict))
          print_forest forest, opt, :unused_keys
          :exit1 unless forest.empty?
        end

        cmd :remove_unused,
            pos: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.remove_unused'),
            args: %i[locales out_format strict keep_order confirm pattern]

        def remove_unused(opt = {}) # rubocop:disable Metrics/AbcSize
          unused_keys = i18n.unused_keys(**opt.slice(:locales, :strict))

          if opt[:pattern]
            pattern_re = i18n.compile_key_pattern(opt[:pattern])
            unused_keys = unused_keys.select_keys { |full_key, _node| full_key =~ pattern_re }
          end

          if unused_keys.present?
            terminal_report.unused_keys(unused_keys)
            confirm_remove_unused!(unused_keys, opt)
            i18n.data.config = i18n.data.config.merge(sort: false) if opt[:'keep-order']
            removed = i18n.data.remove_by_key!(unused_keys)
            log_stderr t('i18n_tasks.remove_unused.removed', count: unused_keys.leaves.count)
            print_forest removed, opt
          else
            log_stderr Rainbow(t('i18n_tasks.remove_unused.noop')).green.bright
          end
        end

        private

        def confirm_remove_unused!(unused_keys, opt)
          return if ENV['CONFIRM'] || opt[:confirm]

          locales = Rainbow(unused_keys.flat_map { |root| root.key.split('+') }.sort.uniq * ', ').bright
          msg     = [
            Rainbow(t('i18n_tasks.remove_unused.confirm', count: unused_keys.leaves.count, locales: locales)).red,
            Rainbow(t('i18n_tasks.common.continue_q')).yellow,
            Rainbow('(yes/no)').yellow
          ].join(' ')
          exit 1 unless agree msg
        end
      end
    end
  end
end
