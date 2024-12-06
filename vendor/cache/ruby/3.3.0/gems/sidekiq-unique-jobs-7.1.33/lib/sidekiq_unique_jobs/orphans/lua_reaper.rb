# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    #
    # Class DeleteOrphans provides deletion of orphaned digests
    #
    # @note this is a much slower version of the lua script but does not crash redis
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class LuaReaper < Reaper
      #
      # Delete orphaned digests
      #
      #
      # @return [Integer] the number of reaped locks
      #
      def call
        call_script(
          :reap_orphans,
          conn,
          keys: [DIGESTS, EXPIRING_DIGESTS, SCHEDULE, RETRY, PROCESSES],
          argv: [reaper_count, (Time.now - reaper_timeout).to_f],
        )
      end
    end
  end
end
