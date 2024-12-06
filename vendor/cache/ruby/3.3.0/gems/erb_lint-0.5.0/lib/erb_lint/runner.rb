# frozen_string_literal: true

module ERBLint
  # Runs all enabled linters against an html.erb file.
  class Runner
    attr_reader :offenses

    def initialize(file_loader, config, disable_inline_configs = false)
      @file_loader = file_loader
      @config = config || RunnerConfig.default
      raise ArgumentError, "expect `config` to be a RunnerConfig instance" unless @config.is_a?(RunnerConfig)

      linter_classes = LinterRegistry.linters.select do |klass|
        @config.for_linter(klass).enabled? && klass != ERBLint::Linters::NoUnusedDisable
      end
      @linters = linter_classes.map do |linter_class|
        linter_class.new(@file_loader, @config.for_linter(linter_class))
      end
      @no_unused_disable = nil
      @disable_inline_configs = disable_inline_configs
      @offenses = []
    end

    def run(processed_source)
      @linters
        .reject { |linter| linter.excludes_file?(processed_source.filename) }
        .each do |linter|
        linter.run_and_update_offense_status(processed_source, enable_inline_configs?)
        @offenses.concat(linter.offenses)
      end
      report_unused_disable(processed_source)
      @offenses = @offenses.reject(&:disabled?)
    end

    def clear_offenses
      @offenses = []
      @linters.each(&:clear_offenses)
      @no_unused_disable&.clear_offenses
    end

    def restore_offenses(offenses)
      @offenses.concat(offenses)
    end

    private

    def enable_inline_configs?
      !@disable_inline_configs
    end

    def no_unused_disable_enabled?
      LinterRegistry.linters.include?(ERBLint::Linters::NoUnusedDisable) &&
        @config.for_linter(ERBLint::Linters::NoUnusedDisable).enabled?
    end

    def report_unused_disable(processed_source)
      if no_unused_disable_enabled? && enable_inline_configs?
        @no_unused_disable = ERBLint::Linters::NoUnusedDisable.new(
          @file_loader,
          @config.for_linter(ERBLint::Linters::NoUnusedDisable)
        )
        @no_unused_disable.run(processed_source, @offenses)
        @offenses.concat(@no_unused_disable.offenses)
      end
    end
  end
end
