module Sidekiq
  class ThrottleHoneycombTracking
    # @param [Object] worker the worker instance
    # @param [Hash] job the full job payload
    #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
    # @param [String] queue the name of the queue the job was pulled from
    def call(worker, _job, _queue)
      # For workers that create a lot of Honeycomb events, ie looping through all user records,
      # this allows us to throttle sending those events to Honeycomb to avoid giant traces
      if worker.sidekiq_options_hash["throttle_honeycomb_tracking"]
        # We set this field on the current_trace so every child event can access
        # and check it in the Honeycomb::NoiseCancellingSampler
        Honeycomb.current_trace.fields["throttle_sql_events"] = true
      end

      yield
    end
  end
end
