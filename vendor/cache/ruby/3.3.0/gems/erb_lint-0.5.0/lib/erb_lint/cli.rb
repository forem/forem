# frozen_string_literal: true

require "erb_lint/all"
require "active_support"
require "active_support/inflector"
require "optparse"
require "psych"
require "yaml"
require "rainbow"
require "erb_lint/utils/severity_levels"

module ERBLint
  class CLI
    include Utils::SeverityLevels

    DEFAULT_CONFIG_FILENAME = ".erb-lint.yml"
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

      if cache? && autocorrect?
        failure!("cannot run autocorrect mode with cache")
      end

      @files = @options[:stdin] || dupped_args

      load_config

      cache_dir = @options[:cache_dir]
      @cache = Cache.new(@config, cache_dir) if cache? || clear_cache?

      if clear_cache?
        if cache.cache_dir_exists?
          cache.clear
          success!("cache directory cleared")
        else
          failure!("cache directory doesn't exist, skipping deletion.")
        end
      end

      if !@files.empty? && lint_files.empty?
        if allow_no_files?
          success!("no files found...\n")
        else
          failure!("no files found...\n")
        end
      elsif lint_files.empty?
        failure!("no files found or given, specify files or config...\n#{option_parser}")
      end

      ensure_files_exist(lint_files)

      if enabled_linter_classes.empty?
        failure!("no linter available with current configuration")
      end

      @options[:format] ||= :multiline
      @options[:fail_level] ||= severity_level_for_name(:refactor)
      @options[:disable_inline_configs] ||= false
      @stats.files = lint_files.size
      @stats.linters = enabled_linter_classes.size
      @stats.autocorrectable_linters = enabled_linter_classes.count(&:support_autocorrect?)

      reporter = Reporter.create_reporter(@options[:format], @stats, autocorrect?)
      reporter.preview

      runner = ERBLint::Runner.new(file_loader, @config, @options[:disable_inline_configs])
      file_content = nil

      lint_files.each do |filename|
        runner.clear_offenses
        begin
          file_content = run_on_file(runner, filename)
        rescue => e
          @stats.exceptions += 1
          puts "Exception occurred when processing: #{relative_filename(filename)}"
          puts "If this file cannot be processed by erb-lint, "\
            "you can exclude it in your configuration file."
          puts e.message
          puts Rainbow(e.backtrace.join("\n")).red
          puts
        end
      end

      cache&.close

      reporter.show

      if stdin? && autocorrect?
        # When running from stdin, we only lint a single file
        puts "================ #{lint_files.first} ==================\n"
        puts file_content
      end

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

    attr_reader :cache, :config

    def run_on_file(runner, filename)
      file_content = read_content(filename)

      if cache? && !autocorrect?
        run_using_cache(runner, filename, file_content)
      else
        file_content = run_with_corrections(runner, filename, file_content)
      end

      log_offense_stats(runner, filename)
      file_content
    end

    def run_using_cache(runner, filename, file_content)
      if (cache_result_offenses = cache.get(filename, file_content))
        runner.restore_offenses(cache_result_offenses)
      else
        run_with_corrections(runner, filename, file_content)
        cache.set(filename, file_content, runner.offenses.map(&:to_cached_offense_hash).to_json)
      end
    end

    def autocorrect?
      @options[:autocorrect]
    end

    def cache?
      @options[:cache]
    end

    def clear_cache?
      @options[:clear_cache]
    end

    def run_with_corrections(runner, filename, file_content)
      7.times do
        processed_source = ERBLint::ProcessedSource.new(filename, file_content)
        runner.run(processed_source)
        break unless autocorrect? && runner.offenses.any?

        corrector = correct(processed_source, runner.offenses)
        break if corrector.corrections.empty?
        break if processed_source.file_content == corrector.corrected_content

        @stats.corrected += corrector.corrections.size

        # Don't overwrite the file if the input comes from stdin
        unless stdin?
          File.open(filename, "wb") do |file|
            file.write(corrector.corrected_content)
          end
        end

        file_content = corrector.corrected_content
        runner.clear_offenses
      end

      file_content
    end

    def log_offense_stats(runner, filename)
      offenses_filename = relative_filename(filename)
      offenses = runner.offenses || []

      @stats.ignored, @stats.found = offenses.partition do |offense|
        severity_level_for_name(offense.severity) < @options[:fail_level]
      end.map(&:size)
        .zip([@stats.ignored, @stats.found])
        .map(&:sum)

      @stats.processed_files[offenses_filename] ||= []
      @stats.processed_files[offenses_filename] |= offenses
    end

    def read_content(filename)
      return File.read(filename, encoding: Encoding::UTF_8) unless stdin?

      $stdin.binmode.read.force_encoding(Encoding::UTF_8)
    end

    def correct(processed_source, offenses)
      corrector = ERBLint::Corrector.new(processed_source, offenses)
      failure!(corrector.diagnostics.join(", ")) if corrector.diagnostics.any?
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
      @config&.merge!(runner_config_override)
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
            .map { |f| f.include?("*") ? Dir[f] : f }
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
        expanded_path = File.expand_path(path, Dir.pwd)
        File.fnmatch?(expanded_path, filename)
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
        .select { |klass| enabled_linter_names.include?(klass.simple_name.underscore) }
    end

    def relative_filename(filename)
      filename.sub("#{File.expand_path(".", Dir.pwd)}/", "")
    end

    def runner_config_override
      RunnerConfig.new(
        linters: {}.tap do |linters|
          ERBLint::LinterRegistry.linters.map do |klass|
            linters[klass.simple_name] = { "enabled" => enabled_linter_classes.include?(klass) }
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

        opts.on("-f", "--format FORMAT", format_options_help) do |format|
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

        opts.on("--cache", "Enable caching") do |config|
          @options[:cache] = config
        end

        opts.on("--cache-dir DIR", "Set the cache directory") do |dir|
          @options[:cache_dir] = dir
        end

        opts.on("--clear-cache", "Clear cache") do |config|
          @options[:clear_cache] = config
        end

        opts.on("--enable-linters LINTER[,LINTER,...]", Array,
          "Only use specified linter", "Known linters are: #{known_linter_names.join(", ")}") do |linters|
          linters.each do |linter|
            unless known_linter_names.include?(linter)
              failure!("#{linter}: not a valid linter name (#{known_linter_names.join(", ")})")
            end
          end
          @options[:enabled_linters] = linters
        end

        opts.on("--fail-level SEVERITY", "Minimum severity for exit with error code") do |level|
          parsed_severity = SEVERITY_CODE_TABLE[level.upcase.to_sym] || (SEVERITY_NAMES & [level.downcase]).first

          if parsed_severity.nil?
            failure!("#{level}: not a valid failure level (#{SEVERITY_NAMES.join(", ")})")
          end
          @options[:fail_level] = severity_level_for_name(parsed_severity)
        end

        opts.on("-a", "--autocorrect", "Correct offenses automatically if possible (default: false)") do |config|
          @options[:autocorrect] = config
        end

        opts.on("--allow-no-files", "When no matching files found, exit successfully (default: false)") do |config|
          @options[:allow_no_files] = config
        end

        opts.on("--disable-inline-configs", "Report all offenses while ignoring inline disable comments") do
          @options[:disable_inline_configs] = true
        end

        opts.on(
          "-sFILE",
          "--stdin FILE",
          "Pipe source from STDIN. Takes the path to be used to check which rules to apply."
        ) do |file|
          @options[:stdin] = [file]
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
        "(#{Reporter.available_formats.join(", ")}) (default: multiline)"
    end

    def invalid_format_error_message(given_format)
      formats = Reporter.available_formats.map { |format| "  - #{format}\n" }
      "#{given_format}: is not a valid format. Available formats:\n#{formats.join}"
    end

    def stdin?
      @options[:stdin].present?
    end

    def allow_no_files?
      @options[:allow_no_files]
    end
  end
end
