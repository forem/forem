# frozen_string_literal: true

require 'i18n/tasks/command/option_parsers/enum'

module I18n::Tasks
  module Command
    module Options
      module Data
        include Command::DSL

        DATA_FORMATS = %w[yaml json keys].freeze
        OUT_FORMATS  = ['terminal-table', *DATA_FORMATS, 'inspect', 'key-values'].freeze

        format_arg = proc do |type, values|
          default = values.first
          arg type,
              '-f',
              '--format FORMAT',
              values,
              { 'yml' => 'yaml' },
              t("i18n_tasks.cmd.args.desc.#{type}", valid_text: values * ', ', default_text: default),
              parser: OptionParsers::Enum::Parser.new(values,
                                                      proc do |value, valid|
                                                        I18n.t('i18n_tasks.cmd.errors.invalid_format',
                                                               invalid: value, valid: valid * ', ')
                                                      end)
        end

        # i18n-tasks-use t('i18n_tasks.cmd.args.desc.data_format')
        format_arg.call(:data_format, DATA_FORMATS)

        # i18n-tasks-use t('i18n_tasks.cmd.args.desc.out_format')
        format_arg.call(:out_format, OUT_FORMATS)

        # @return [I18n::Tasks::Data::Tree::Siblings]
        def forest_pos_or_stdin!(opt, format = opt[:format])
          parse_forest(pos_or_stdin!(opt), format)
        end

        # @return [Array<I18n::Tasks::Data::Tree::Siblings>] trees read from stdin and positional arguments
        def forests_stdin_and_pos!(opt, num = false, format = opt[:format])
          args = opt[:arguments] || []
          if opt[:nostdin]
            sources = []
          else
            sources = [$stdin.read]
            num -= 1 if num
          end
          if num
            num.times { sources << args.shift }
          else
            sources += args
            args.clear
          end
          sources.map { |src| parse_forest(src, format) }
        end

        def merge_forests_stdin_and_pos!(opt)
          forests_stdin_and_pos!(opt).inject(i18n.empty_forest) do |result, forest|
            result.merge! forest
          end
        end

        # @return [I18n::Tasks::Data::Tree::Siblings]
        def parse_forest(src, format)
          fail CommandError, I18n.t('i18n_tasks.cmd.errors.pass_forest') unless src

          if format == 'keys'
            ::I18n::Tasks::Data::Tree::Siblings.from_key_names parse_keys(src)
          else
            ::I18n::Tasks::Data::Tree::Siblings.from_nested_hash i18n.data.adapter_parse(src, format)
          end
        end

        def parse_keys(src)
          Array(src).compact.flat_map { |v| v.strip.split(/\s*[,\s\n]\s*/) }.map(&:presence).compact
        end

        def print_forest(forest, opts, version = :show_tree)
          format = opts[:format].to_s
          case format
          when 'terminal-table'
            terminal_report.send(version, forest)
          when 'inspect'
            puts forest.inspect
          when 'keys'
            puts forest.key_names(root: true)
          when 'key-values'
            puts(forest.key_values(root: true).map { |kv| kv.join("\t") })
          when *DATA_FORMATS
            puts i18n.data.adapter_dump forest.to_hash(true), format
          end
        end
      end
    end
  end
end
