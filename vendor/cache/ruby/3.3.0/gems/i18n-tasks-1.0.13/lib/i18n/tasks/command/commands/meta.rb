# frozen_string_literal: true

module I18n::Tasks
  module Command
    module Commands
      module Meta
        include Command::Collection

        cmd :config,
            pos: '[section ...]',
            desc: t('i18n_tasks.cmd.desc.config')

        def config(opts = {})
          cfg = i18n.config_for_inspect
          cfg = cfg.slice(*opts[:arguments]) if opts[:arguments].present?
          cfg = cfg.to_yaml
          cfg.sub!(/\A---\n/, '')
          cfg.gsub!(/^([^\s-].+?:)/, Rainbow('\1').cyan.bright)
          puts cfg
        end

        cmd :gem_path, desc: t('i18n_tasks.cmd.desc.gem_path')

        def gem_path
          puts I18n::Tasks.gem_path
        end

        cmd :irb, desc: t('i18n_tasks.cmd.desc.irb')

        def irb
          require 'i18n/tasks/console_context'
          ::I18n::Tasks::ConsoleContext.start
        end
      end
    end
  end
end
