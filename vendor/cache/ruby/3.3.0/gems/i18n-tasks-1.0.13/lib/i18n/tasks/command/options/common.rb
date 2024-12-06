# frozen_string_literal: true

require 'i18n/tasks/command/dsl'

module I18n::Tasks
  module Command
    module Options
      module Common
        include Command::DSL

        arg :nostdin,
            '-S',
            '--nostdin',
            t('i18n_tasks.cmd.args.desc.nostdin')

        arg :confirm,
            '-y',
            '--confirm',
            desc: t('i18n_tasks.cmd.args.desc.confirm')

        arg :pattern,
            '-p',
            '--pattern PATTERN',
            t('i18n_tasks.cmd.args.desc.key_pattern')

        arg :value,
            '-v',
            '--value VALUE',
            t('i18n_tasks.cmd.args.desc.value')

        arg :config,
            '-c',
            '--config FILE',
            t('i18n_tasks.cmd.args.desc.config')

        def arg_or_pos!(key, opts)
          opts[key] ||= opts[:arguments].try(:shift)
        end

        def pos_or_stdin!(opts)
          opts[:arguments].try(:shift) || $stdin.read
        end
      end
    end
  end
end
