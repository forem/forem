# frozen_string_literal: true

require "erb_lint/utils/inline_configs"

module ERBLint
  # Defines common functionality available to all linters.
  class Linter
    class << self
      attr_accessor :simple_name
      attr_accessor :config_schema

      # When defining a Linter class, define its simple name as well. This
      # assumes that the module hierarchy of every linter starts with
      # `ERBLint::Linters::`, and removes this part of the class name.
      #
      # `ERBLint::Linters::Foo.simple_name`          #=> "Foo"
      # `ERBLint::Linters::Compass::Bar.simple_name` #=> "Compass::Bar"
      def inherited(linter)
        super
        linter.simple_name = if linter.name.start_with?("ERBLint::Linters::")
          name_parts = linter.name.split("::")
          name_parts[2..-1].join("::")
        else
          linter.name
        end

        linter.config_schema = LinterConfig
      end

      def support_autocorrect?
        method_defined?(:autocorrect)
      end
    end

    attr_reader :offenses, :config

    # Must be implemented by the concrete inheriting class.
    def initialize(file_loader, config)
      @file_loader = file_loader
      @config = config
      raise ArgumentError, "expect `config` to be #{self.class.config_schema} instance, "\
        "not #{config.class}" unless config.is_a?(self.class.config_schema)
      @offenses = []
    end

    def enabled?
      @config.enabled?
    end

    def excludes_file?(filename)
      @config.excludes_file?(filename, @file_loader.base_path)
    end

    def run(_processed_source)
      raise NotImplementedError, "must implement ##{__method__}"
    end

    def run_and_update_offense_status(processed_source, enable_inline_configs = true)
      run(processed_source)
      if @offenses.any? && enable_inline_configs
        update_offense_status(processed_source)
      end
    end

    def add_offense(source_range, message, context = nil, severity = nil)
      @offenses << Offense.new(self, source_range, message, context, severity)
    end

    def clear_offenses
      @offenses = []
    end

    private

    def update_offense_status(processed_source)
      @offenses.each do |offense|
        offense_line_range = offense.source_range.line_range
        offense_lines = source_for_line_range(processed_source, offense_line_range)

        if Utils::InlineConfigs.rule_disable_comment_for_lines?(self.class.simple_name, offense_lines)
          offense.disabled = true
        end
      end
    end

    def source_for_line_range(processed_source, line_range)
      processed_source.source_buffer.source_lines[line_range.first - 1..line_range.last - 1].join
    end
  end
end
