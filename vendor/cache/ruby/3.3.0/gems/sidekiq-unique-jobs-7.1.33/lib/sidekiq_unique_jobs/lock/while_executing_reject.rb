# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs while executing
    #   Locks from the server process
    #   Unlocks after the server is done processing
    #
    # See {#lock} for more information about the client.
    # See {#execute} for more information about the server
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class WhileExecutingReject < WhileExecuting
      # Overridden with a forced {OnConflict::Reject} strategy
      # @return [OnConflict::Reject] a reject strategy
      def server_strategy
        @server_strategy ||= OnConflict.find_strategy(:reject).new(item, redis_pool)
      end
    end
  end
end
