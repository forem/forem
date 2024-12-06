# frozen_string_literal: true

require "ruby-next"

require "ruby-next/commands/base"
require "ruby-next/commands/nextify"
require "ruby-next/commands/core_ext"

module RubyNext
  # Command line interface for RubyNext
  class CLI
    class << self
      attr_accessor :verbose, :dry_run

      alias verbose? verbose
      alias dry_run? dry_run
    end

    self.verbose = false
    self.dry_run = false

    COMMANDS = {
      "nextify" => Commands::Nextify,
      "core_ext" => Commands::CoreExt
    }.freeze

    def run(args = ARGV)
      maybe_print_version(args)

      command = extract_command(args)

      # Handle top-level help
      unless command
        maybe_print_help
        raise "Command must be specified!"
      end

      args.delete(command)

      args.unshift(*load_args_from_rc(command))

      COMMANDS.fetch(command) do
        raise "Unknown command: #{command}. Available commands: #{COMMANDS.keys.join(",")}"
      end.run(args)
    end

    private

    def maybe_print_version(args)
      args = args.dup
      begin
        optparser.parse!(args)
      rescue OptionParser::InvalidOption
        # skip and pass all args to the command's parser
      end
    end

    def maybe_print_help
      return unless @print_help

      $stdout.puts optparser.help
      exit 0
    end

    def extract_command(source_args)
      args = source_args.dup
      unknown_args = []
      command = nil
      begin
        command, = optparser.permute!(args)
      rescue OptionParser::InvalidOption => e
        unknown_args += e.args
        args = source_args - unknown_args
        retry
      end
      command
    end

    def optparser
      @optparser ||= OptionParser.new do |opts|
        opts.banner = "Usage: ruby-next COMMAND [options]"

        opts.on("-v", "--version", "Print version") do
          $stdout.puts RubyNext::VERSION
          exit 0
        end

        opts.on("-h", "--help", "Print help") do
          @print_help = true
        end
      end
    end

    def load_args_from_rc(command)
      return [] unless File.file?(".rbnextrc")

      require "yaml"
      command_args = YAML.load_file(".rbnextrc")[command]
      return [] unless command_args

      command_args.lines.flat_map { |line| line.chomp.split(/\s+/) }
    end
  end
end
