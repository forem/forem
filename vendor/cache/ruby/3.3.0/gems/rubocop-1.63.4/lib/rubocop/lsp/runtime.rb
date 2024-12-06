# frozen_string_literal: true

#
# This code is based on https://github.com/standardrb/standard.
#
# Copyright (c) 2023 Test Double, Inc.
#
# The MIT License (MIT)
#
# https://github.com/standardrb/standard/blob/main/LICENSE.txt
#
module RuboCop
  module LSP
    # Runtime for Language Server Protocol of RuboCop.
    # @api private
    class Runtime
      attr_writer :safe_autocorrect, :lint_mode, :layout_mode

      def initialize(config_store)
        @config_store = config_store
        @logged_paths = []
        @safe_autocorrect = true
        @lint_mode = false
        @layout_mode = false
      end

      # This abuses the `--stdin` option of rubocop and reads the formatted text
      # from the `options[:stdin]` that rubocop mutates. This depends on
      # `parallel: false` as well as the fact that RuboCop doesn't otherwise dup
      # or reassign that options object. Risky business!
      #
      # Reassigning `options[:stdin]` is done here:
      #   https://github.com/rubocop/rubocop/blob/v1.52.0/lib/rubocop/cop/team.rb#L131
      # Printing `options[:stdin]`
      #   https://github.com/rubocop/rubocop/blob/v1.52.0/lib/rubocop/cli/command/execute_runner.rb#L95
      # Setting `parallel: true` would break this here:
      #   https://github.com/rubocop/rubocop/blob/v1.52.0/lib/rubocop/runner.rb#L72
      def format(path, text, command:)
        safe_autocorrect = if command
                             command == 'rubocop.formatAutocorrects'
                           else
                             @safe_autocorrect
                           end

        formatting_options = {
          stdin: text, force_exclusion: true, autocorrect: true, safe_autocorrect: safe_autocorrect
        }
        formatting_options[:only] = config_only_options if @lint_mode || @layout_mode

        redirect_stdout { run_rubocop(formatting_options, path) }

        formatting_options[:stdin]
      end

      def offenses(path, text)
        diagnostic_options = {
          stdin: text, force_exclusion: true, formatters: ['json'], format: 'json'
        }
        diagnostic_options[:only] = config_only_options if @lint_mode || @layout_mode

        json = redirect_stdout { run_rubocop(diagnostic_options, path) }
        results = JSON.parse(json, symbolize_names: true)

        if results[:files].empty?
          unless @logged_paths.include?(path)
            Logger.log "Ignoring file, per configuration: #{path}"
            @logged_paths << path
          end
          return []
        end

        results.dig(:files, 0, :offenses)
      end

      private

      def config_only_options
        only_options = []
        only_options << 'Lint' if @lint_mode
        only_options << 'Layout' if @layout_mode
        only_options
      end

      def redirect_stdout(&block)
        stdout = StringIO.new

        RuboCop::Server::Helper.redirect(stdout: stdout, &block)

        stdout.string
      end

      def run_rubocop(options, path)
        runner = RuboCop::Runner.new(options, @config_store)

        runner.run([path])
      end
    end
  end
end
