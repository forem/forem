# frozen_string_literal: true

require "thor"

module SidekiqUniqueJobs
  #
  # Command line interface for unique jobs
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class Cli < Thor
    # :nodoc:
    # rubocop:disable Style/OptionalBooleanParameter
    def self.banner(command, _namespace = nil, _subcommand = false) # rubocop:disable Style/OptionalBooleanParameter
      "jobs #{@package_name} #{command.usage}" # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
    end
    # rubocop:enable Style/OptionalBooleanParameter

    desc "list PATTERN", "list all unique digests and their expiry time"
    option :count, aliases: :c, type: :numeric, default: 1000, desc: "The max number of digests to return"
    # :nodoc:
    def list(pattern = "*")
      max_count = options[:count]
      say "Searching for regular digests"
      list_entries(digests.entries(pattern: pattern, count: max_count), pattern)
      say "Searching for expiring digests"
      list_entries(expiring_digests.entries(pattern: pattern, count: max_count), pattern)
    end

    desc "del PATTERN", "deletes unique digests from redis by pattern"
    option :dry_run, aliases: :d, type: :boolean, desc: "set to false to perform deletion"
    option :count, aliases: :c, type: :numeric, default: 1000, desc: "The max number of digests to return"
    # :nodoc:
    def del(pattern)
      max_count = options[:count]
      if options[:dry_run]
        count_entries_for_del(max_count, pattern)
      else
        del_entries(max_count, pattern)
      end
    end

    desc "console", "drop into a console with easy access to helper methods"
    # :nodoc:
    def console
      say "Use `list '*', 1000 to display the first 1000 unique digests matching '*'"
      say "Use `del '*', 1000, true (default) to see how many digests would be deleted for the pattern '*'"
      say "Use `del '*', 1000, false to delete the first 1000 digests matching '*'"

      # Object.include SidekiqUniqueJobs::Api
      console_class.start
    end

    no_commands do # rubocop:disable Metrics/BlockLength
      # :nodoc:
      def digests
        @digests ||= SidekiqUniqueJobs::Digests.new
      end

      # :nodoc:
      def expiring_digests
        @expiring_digests ||= SidekiqUniqueJobs::ExpiringDigests.new
      end

      # :nodoc:
      def console_class
        require "pry"
        Pry
      rescue NameError, LoadError
        require "irb"
        IRB
      end

      # :nodoc:
      def list_entries(entries, pattern)
        say "Found #{entries.size} digests matching '#{pattern}':"
        print_in_columns(entries.sort) if entries.any?
      end

      # :nodoc:
      def count_entries_for_del(max_count, pattern)
        count = digests.entries(pattern: pattern, count: max_count).size +
                expiring_digests.entries(pattern: pattern, count: max_count).size
        say "Would delete #{count} digests matching '#{pattern}'"
      end

      # :nodoc:
      def del_entries(max_count, pattern)
        deleted_count = digests.delete_by_pattern(pattern, count: max_count).to_i +
                        expiring_digests.delete_by_pattern(pattern, count: max_count).to_i
        say "Deleted #{deleted_count} digests matching '#{pattern}'"
      end
    end
  end
end
