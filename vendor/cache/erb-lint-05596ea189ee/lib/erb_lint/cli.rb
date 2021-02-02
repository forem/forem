# frozen_string_literal: true

require 'erb_lint'
require 'active_support'
require 'active_support/inflector'
require 'optparse'
require 'psych'
require 'yaml'
require 'rainbow'

module ERBLint
  class CLI
    DEFAULT_CONFIG_FILENAME = '.erb-lint.yml'
    DEFAULT_LINT_ALL_GLOB = "**/*.html{+*,}.erb"

    class ExitWithFailure < RuntimeError; end

    class ExitWithSuccess < RuntimeError; end

    def initialize
      @options = {}
      @config = nil
      @files = []
      @stats = Stats.new
    end

    def run(args = ARGV)
      dupped_args = args.dup
      load_options(dupped_args)
      @files = dupped_args

      load_config

      if !@files.empty? && lint_files.empty?
        failure!("no files found...\n")
      elsif lint_files.empty?
        failure!("no files found or given, specify files or config...\n#{option_parser}")
      end

      ensure_files_exist(lint_files)

      if enabled_linter_classes.empty?
        failure!('no linter available with current configuration')
      end

      @options[:format] ||= :multiline
      @stats.files = lint_files.size
      @stats.linters = enabled_linter_classes.size

      reporter = Reporter.create_reporter(@options[:format], @stats, autocorrect?)
      reporter.preview

      runner = ERBLint::Runner.new(file_loader, @config)

      lint_files.each do |filename|
        runner.clear_offenses
        begin
          run_with_corrections(runner, filename)
        rescue => e
          @stats.exceptions += 1
          puts "Exception occured when processing: #{relative_filename(filename)}"
          puts "If this file cannot be processed by erb-lint, "\
            "you can exclude it in your configuration file."
          puts e.message
          puts Rainbow(e.backtrace.join("\n")).red
          puts
        end
      end

      reporter.show

      @stats.found == 0 && @stats.exceptions == 0
    rescue OptionParser::InvalidOption, OptionParser::InvalidArgument, ExitWithFailure => e
      warn(Rainbow(e.message).red)
      false
    rescue ExitWithSuccess => e
      puts e.message
      true
    rescue => e
      warn(Rainbow("#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}").red)
      false
    end

    private

    def autocorrect?
      @options[:autocorrect]
    end

    def run_with_corrections(runner, filename)
      file_content = File.read(filename, encoding: Encoding::UTF_8)

      7.times do
        processed_source = ERBLint::ProcessedSource.new(filename, file_content)
        runner.run(processed_source)
        break unless autocorrect? && runner.offenses.any?

        corrector = correct(processed_source, runner.offenses)
        break if corrector.corrections.empty?
        break if processed_source.file_content == corrector.corrected_content

        @stats.corrected += corrector.corrections.size

        File.open(filename, "wb") do |file|
          file.write(corrector.corrected_content)
        end

        file_content = corrector.corrected_content
        runner.clear_offenses
      end
      offenses_filename = relative_filename(filename)
      offenses = runner.offenses || []

      @stats.found += offenses.size
      @stats.processed_files[offenses_filename] ||= []
      @stats.processed_files[offenses_filename] |= offenses
    end

    def correct(processed_source, offenses)
      corrector = ERBLint::Corrector.new(processed_source, offenses)
      failure!(corrector.diagnostics.join(', ')) if corrector.diagnostics.any?
      corrector
    end

    def config_filename
      @config_filename ||= @options[:config] || DEFAULT_CONFIG_FILENAME
    end

    def load_config
      if File.exist?(config_filename)
        config = RunnerConfig.new(file_loader.yaml(config_filename), file_loader)
        @config = RunnerConfig.default_for(config)
      else
        warn(Rainbow("#{config_filename} not found: using default config").yellow)
        @config = RunnerConfig.default
      end
    rescue Psych::SyntaxError => e
      failure!("error parsing config: #{e.message}")
    ensure
      @config.merge!(runner_config_override)
    end

    def file_loader
      @file_loader ||= ERBLint::FileLoader.new(Dir.pwd)
    end

    def load_options(args)
      option_parser.parse!(args)
    end

    def lint_files
      @lint_files ||=
        if @options[:lint_all]
          pattern = File.expand_path(glob, Dir.pwd)
          Dir[pattern].select { |filename| !excluded?(filename) }
        else
          @files
            .map { |f| Dir.exist?(f) ? Dir[File.join(f, glob)] : f }
            .map { |f| f.include?('*') ? Dir[f] : f }
            .flatten
            .map { |f| File.expand_path(f, Dir.pwd) }
            .select { |filename| !excluded?(filename) }
        end
    end

    def glob
      @config.to_hash["glob"] || DEFAULT_LINT_ALL_GLOB
    end

    def excluded?(filename)
      @config.global_exclude.any? do |path|
        File.fnmatch?(path, filename)
      end
    end

    def failure!(msg)
      raise ExitWithFailure, msg
    end

    def success!(msg)
      raise ExitWithSuccess, msg
    end

    def ensure_files_exist(files)
      files.each do |filename|
        unless File.exist?(filename)
          failure!("#{filename}: does not exist")
        end
      end
    end

    def known_linter_names
      @known_linter_names ||= ERBLint::LinterRegistry.linters
        .map(&:simple_name)
        .map(&:underscore)
    end

    def enabled_linter_names
      @enabled_linter_names ||=
        @options[:enabled_linters] ||
        known_linter_names
          .select { |name| @config.for_linter(name.camelize).enabled? }
    end

    def enabled_linter_classes
      @enabled_linter_classes ||= ERBLint::LinterRegistry.linters
        .select { |klass| linter_can_run?(klass) && enabled_linter_names.include?(klass.simple_name.underscore) }
    end

    def linter_can_run?(klass)
      !autocorrect? || klass.support_autocorrect?
    end

    def relative_filename(filename)
      filename.sub("#{File.expand_path('.', Dir.pwd)}/", '')
    end

    def runner_config_override
      RunnerConfig.new(
        linters: {}.tap do |linters|
          ERBLint::LinterRegistry.linters.map do |klass|
            linters[klass.simple_name] = { 'enabled' => enabled_linter_classes.include?(klass) }
          end
        end
      )
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: erblint [options] [file1, file2, ...]"

        opts.on("--config FILENAME", "Config file [default: #{DEFAULT_CONFIG_FILENAME}]") do |config|
          if File.exist?(config)
            @options[:config] = config
          else
            failure!("#{config}: does not exist")
          end
        end

        opts.on("--format FORMAT", format_options_help) do |format|
          unless Reporter.available_format?(format)
            error_message = invalid_format_error_message(format)
            failure!(error_message)
          end

          @options[:format] = format
        end

        opts.on("--lint-all", "Lint all files matching configured glob [default: #{DEFAULT_LINT_ALL_GLOB}]") do |config|
          @options[:lint_all] = config
        end

        opts.on("--enable-all-linters", "Enable all known linters") do
          @options[:enabled_linters] = known_linter_names
        end

        opts.on("--enable-linters LINTER[,LINTER,...]", Array,
          "Only use specified linter", "Known linters are: #{known_linter_names.join(', ')}") do |linters|
          linters.each do |linter|
            unless known_linter_names.include?(linter)
              failure!("#{linter}: not a valid linter name (#{known_linter_names.join(', ')})")
            end
          end
          @options[:enabled_linters] = linters
        end

        opts.on("-a", "--autocorrect", "Correct offenses automatically if possible (default: false)") do |config|
          @options[:autocorrect] = config
        end

        opts.on_tail("-h", "--help", "Show this message") do
          success!(opts)
        end

        opts.on_tail("--version", "Show version") do
          success!(ERBLint::VERSION)
        end
      end
    end

    def format_options_help
      "Report offenses in the given format: "\
      "(#{Reporter.available_formats.join(', ')}) (default: multiline)"
    end

    def invalid_format_error_message(given_format)
      formats = Reporter.available_formats.map { |format| "  - #{format}\n" }
      "#{given_format}: is not a valid format. Available formats:\n#{formats.join}"
    end
  end
end
