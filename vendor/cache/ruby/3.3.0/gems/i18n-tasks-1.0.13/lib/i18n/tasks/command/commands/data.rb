# frozen_string_literal: true

module I18n::Tasks
  module Command
    module Commands
      module Data
        include Command::Collection

        arg :pattern_router,
            '-p',
            '--pattern_router',
            t('i18n_tasks.cmd.args.desc.pattern_router')

        cmd :normalize,
            pos: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.normalize'),
            args: %i[locales pattern_router]

        def normalize(opt = {})
          i18n.normalize_store! locales: opt[:locales],
                                force_pattern_router: opt[:pattern_router]
        end

        cmd :check_normalized,
            pos: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.check_normalized'),
            args: %i[locales]

        def check_normalized(opt)
          non_normalized = i18n.non_normalized_paths locales: opt[:locales]
          terminal_report.check_normalized_results(non_normalized)
          :exit1 unless non_normalized.empty?
        end

        cmd :mv,
            pos: 'FROM_KEY_PATTERN TO_KEY_PATTERN',
            desc: t('i18n_tasks.cmd.desc.mv')
        def mv(opt = {})
          fail CommandError, 'requires FROM_KEY_PATTERN and TO_KEY_PATTERN' if opt[:arguments].size < 2

          from_pattern = opt[:arguments].shift
          to_pattern = opt[:arguments].shift
          forest = i18n.data_forest
          results = forest.mv_key!(compile_key_pattern(from_pattern), to_pattern, root: false)
          i18n.data.write forest
          terminal_report.mv_results results
        end

        cmd :rm,
            pos: 'KEY_PATTERN [KEY_PATTERN...]',
            desc: t('i18n_tasks.cmd.desc.rm')
        def rm(opt = {})
          fail CommandError, 'requires KEY_PATTERN' if opt[:arguments].empty?

          forest = i18n.data_forest
          results = opt[:arguments].each_with_object({}) do |key_pattern, h|
            h.merge! forest.mv_key!(compile_key_pattern(key_pattern), '', root: false)
          end
          i18n.data.write forest
          terminal_report.mv_results results
        end

        cmd :data,
            pos: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.data'),
            args: %i[locales out_format]

        def data(opt = {})
          print_forest i18n.data_forest(opt[:locales]), opt
        end

        cmd :data_merge,
            pos: '[tree ...]',
            desc: t('i18n_tasks.cmd.desc.data_merge'),
            args: %i[data_format nostdin]

        def data_merge(opt = {})
          forest = merge_forests_stdin_and_pos!(opt)
          merged = i18n.data.merge!(forest)
          print_forest merged, opt
        end

        cmd :data_write,
            pos: '[tree]',
            desc: t('i18n_tasks.cmd.desc.data_write'),
            args: %i[data_format nostdin]

        def data_write(opt = {})
          forest = forest_pos_or_stdin!(opt)
          i18n.data.write forest
          print_forest forest, opt
        end

        cmd :data_remove,
            pos: '[tree]',
            desc: t('i18n_tasks.cmd.desc.data_remove'),
            args: %i[data_format nostdin]

        def data_remove(opt = {})
          removed = i18n.data.remove_by_key!(forest_pos_or_stdin!(opt))
          log_stderr 'Removed:'
          print_forest removed, opt
        end
      end
    end
  end
end
