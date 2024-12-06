# frozen_string_literal: true

require 'i18n/tasks'
require 'i18n/tasks/commands'
require 'optparse'

class I18n::Tasks::CLI
  include ::I18n::Tasks::Logging

  def self.start(argv)
    new.start(argv)
  end

  def initialize; end

  def start(argv)
    auto_output_coloring do
      exit 1 if run(argv) == :exit1
    rescue OptionParser::ParseError => e
      error e.message, 64
    rescue I18n::Tasks::CommandError => e
      begin
        error e.message, 78
      ensure
        log_verbose e.backtrace * "\n"
      end
    rescue Errno::EPIPE
      # ignore Errno::EPIPE which is throw when pipe breaks, e.g.:
      # i18n-tasks missing | head
      exit 1
    end
  rescue ExecutionError => e
    exit e.exit_code
  end

  def run(argv)
    argv.each_with_index do |arg, i|
      next unless ['--config', '-c'].include?(arg)

      _, config_file = argv.slice!(i, 2)
      if File.exist?(config_file)
        @config_file = config_file
        break
      else
        error "Config file doesn't exist: #{config_file}", 128
      end
    end

    I18n.with_locale(base_task(config_file: @config_file).internal_locale) do
      name, *options = parse!(argv.dup)
      context.run(name, *options)
    end
  end

  def context
    @context ||= ::I18n::Tasks::Commands.new(base_task)
  end

  def commands
    # load base task to initialize plugins
    base_task
    @commands ||= ::I18n::Tasks::Commands.cmds.transform_keys { |k| k.to_s.tr('_', '-') }
  end

  private

  def base_task(config_file: nil)
    @base_task ||= I18n::Tasks::BaseTask.new(config_file: config_file)
  end

  def parse!(argv)
    command = parse_command! argv
    options = optparse! command, argv
    parse_options! options, command, argv
    [command.tr('-', '_'), options.update(arguments: argv)]
  end

  def optparse!(command, argv)
    if command
      optparse_command!(command, argv)
    else
      optparse_no_command!(argv)
    end
  end

  def optparse_command!(command, argv)
    cmd_conf = commands[command]
    flags    = cmd_conf[:args].dup
    options  = {}
    OptionParser.new("Usage: #{program_name} #{command} [options] #{cmd_conf[:pos]}".strip) do |op|
      flags.each do |flag|
        op.on(*optparse_args(flag)) { |v| options[option_name(flag)] = v }
      end
      verbose_option op
      help_option op
    end.parse!(argv)
    options
  end

  def optparse_no_command!(argv)
    argv << '--help' if argv.empty?
    OptionParser.new("Usage: #{program_name} [command] [options]") do |op|
      op.on('-v', '--version', 'Print the version') do
        puts I18n::Tasks::VERSION
        exit
      end
      help_option op
      commands_summary op
    end.parse!(argv)
  end

  def allow_help_arg_first!(argv)
    # allow `i18n-tasks --help command` in addition to `i18n-tasks command --help`
    argv[0], argv[1] = argv[1], argv[0] if %w[-h --help].include?(argv[0]) && argv[1] && !argv[1].start_with?('-')
  end

  def parse_command!(argv)
    allow_help_arg_first! argv
    if argv[0] && !argv[0].start_with?('-')
      if commands.keys.include?(argv[0])
        argv.shift
      else
        error "unknown command: #{argv[0]}", 64
      end
    end
  end

  def verbose_option(op)
    op.on('--verbose', 'Verbose output') do
      ::I18n::Tasks.verbose = true
    end
  end

  def help_option(op)
    op.on('-h', '--help', 'Show this message') do
      $stderr.puts op
      exit
    end
  end

  # @param [OptionParser] op
  def commands_summary(op)
    op.separator ''
    op.separator 'Available commands:'
    op.separator ''
    commands.each do |cmd, cmd_conf|
      op.separator "    #{cmd.ljust(op.summary_width + 1, ' ')}#{try_call cmd_conf[:desc]}"
    end
    op.separator ''
    op.separator 'See `i18n-tasks <command> --help` for more information on a specific command.'
  end

  def optparse_args(flag)
    args = flag.dup
    args.map! { |v| try_call v }
    conf = args.extract_options!
    if conf.key?(:default)
      args[-1] = "#{args[-1]}. #{I18n.t('i18n_tasks.cmd.args.default_text', value: conf[:default])}"
    end
    args
  end

  def parse_options!(options, command, argv)
    commands[command][:args].each do |flag|
      name          = option_name flag
      options[name] = parse_option flag, options[name], argv, context
    end
  end

  def parse_option(flag, val, argv, context)
    conf = flag.last.is_a?(Hash) ? flag.last : {}
    if conf[:consume_positional]
      val = Array(val) + Array(flag.include?(Array) ? argv.flat_map { |x| x.split(',') } : argv)
    end
    val = conf[:default] if val.nil? && conf.key?(:default)
    val = conf[:parser].call(val, context) if conf.key?(:parser)
    val
  end

  def option_name(flag)
    flag.detect do |f|
      f.start_with?('--')
    end.sub(/\A--(\[no-\])?/, '').sub(/[^\-\w].*\z/, '').to_sym
  end

  def try_call(v)
    if v.respond_to? :call
      v.call
    else
      v
    end
  end

  def error(message, exit_code)
    log_error message
    fail ExecutionError.new(message, exit_code)
  end

  class ExecutionError < RuntimeError
    attr_reader :exit_code

    def initialize(message, exit_code)
      super(message)
      @exit_code = exit_code
    end
  end

  def auto_output_coloring(coloring = ENV['I18N_TASKS_COLOR'] || $stdout.isatty)
    coloring_was    = Rainbow.enabled
    Rainbow.enabled = coloring
    yield
  ensure
    Rainbow.enabled = coloring_was
  end
end
