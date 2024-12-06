# frozen_string_literal: true

module SidekiqUniqueJobs
  module RSpec
    #
    # Module Matchers provides RSpec matcher for your workers
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module Matchers
      #
      # Class HaveValidSidekiqOptions validates the unique/lock configuration for a worker.
      #
      # @author Mikael Henriksson <mikael@mhenrixon.com>
      #
      class HaveValidSidekiqOptions
        attr_reader :worker, :lock_config, :sidekiq_options

        def matches?(worker)
          @worker          = worker
          @sidekiq_options = worker.get_sidekiq_options
          @lock_config     = SidekiqUniqueJobs.validate_worker(sidekiq_options)
          lock_config.valid?
        end

        # :nodoc:
        def failure_message
          <<~FAILURE_MESSAGE
            Expected #{worker} to have valid sidekiq options but found the following problems:
            #{lock_config.errors_as_string}
          FAILURE_MESSAGE
        end

        # :nodoc:
        def description
          "have valid sidekiq options"
        end
      end

      #
      # RSpec matcher method for validating that a sidekiq worker has valid unique/lock configuration
      #
      #
      # @return [HaveValidSidekiqOptions] an RSpec matcher
      #
      def have_valid_sidekiq_options(*args) # rubocop:disable Naming/PredicateName
        HaveValidSidekiqOptions.new(*args)
      end
    end
  end
end
