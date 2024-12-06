# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class ExpiringDigests provides access to the expiring digests used by until_expired locks
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class ExpiringDigests < Digests
    def initialize
      super(EXPIRING_DIGESTS)
    end
  end
end
