# frozen_string_literal: true

require "optparse"

module RubyNext
  module Commands
    class Base
      class << self
        def run(args)
          new(args).run
        end
      end

      attr_reader :dry_run
      alias dry_run? dry_run

      def initialize(args)
        parse! args
      end

      def parse!(*)
        raise NotImplementedError
      end

      def run
        raise NotImplementedError
      end

      def log(msg)
        return unless CLI.verbose?

        if CLI.dry_run?
          $stdout.puts "[DRY RUN] #{msg}"
        else
          $stdout.puts msg
        end
      end

      def base_parser
        OptionParser.new do |opts|
          yield opts

          opts.on("-V", "Turn on verbose mode") do
            CLI.verbose = true
          end

          opts.on("--dry-run", "Print verbose output without generating files") do
            CLI.dry_run = true
            CLI.verbose = true
          end
        end
      end
    end
  end
end
