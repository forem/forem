# frozen_string_literal: true

require_relative "on_conflict/strategy"
require_relative "on_conflict/null_strategy"
require_relative "on_conflict/log"
require_relative "on_conflict/raise"
require_relative "on_conflict/reject"
require_relative "on_conflict/replace"
require_relative "on_conflict/reschedule"

module SidekiqUniqueJobs
  #
  # Provides lock conflict resolutions
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  module OnConflict
    # A convenience method for using the configured strategies
    def self.strategies
      SidekiqUniqueJobs.strategies
    end

    #
    # Find a strategy to use for conflicting locks
    #
    # @param [Symbol] strategy the key for the strategy
    #
    # @return [OnConflict::Strategy] when found
    # @return [OnConflict::NullStrategy] when no other could be found
    #
    def self.find_strategy(strategy)
      return OnConflict::NullStrategy unless strategy

      strategies.fetch(strategy.to_sym) do
        SidekiqUniqueJobs.logger.warn(
          "No matching implementation for strategy: #{strategy}, returning OnConflict::NullStrategy." \
          " Available strategies are (#{strategies.inspect})",
        )

        OnConflict::NullStrategy
      end
    end
  end
end
