# frozen_string_literal: true

module I18n::Tasks
  module Command
    module Commands
      module Interpolations
        include Command::Collection

        cmd :check_consistent_interpolations,
            pos: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.check_consistent_interpolations'),
            args: %i[locales out_format]

        def check_consistent_interpolations(opt = {})
          forest = i18n.inconsistent_interpolations(**opt.slice(:locales, :base_locale))
          print_forest forest, opt, :inconsistent_interpolations
          :exit1 unless forest.empty?
        end
      end
    end
  end
end
