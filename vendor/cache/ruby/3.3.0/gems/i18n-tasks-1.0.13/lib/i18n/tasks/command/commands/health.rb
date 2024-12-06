# frozen_string_literal: true

module I18n::Tasks
  module Command
    module Commands
      module Health
        include Command::Collection

        cmd :health,
            pos: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.health'),
            args: %i[locales out_format config]

        def health(opt = {})
          forest = i18n.data_forest(opt[:locales])
          stats  = i18n.forest_stats(forest)
          fail CommandError, t('i18n_tasks.health.no_keys_detected') if stats[:key_count].zero?

          terminal_report.forest_stats forest, stats
          [
            missing(**opt),
            unused(**opt),
            check_consistent_interpolations(**opt),
            check_normalized(**opt)
          ].detect { |result| result == :exit1 }
        end
      end
    end
  end
end
