# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Default conflict strategy class that does nothing
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class NullStrategy < OnConflict::Strategy
      # Do nothing on conflict
      # @return [nil]
      def call
        # NOOP
      end
    end
  end
end
