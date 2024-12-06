require_relative "resets_state"

module CypressRails
  class TracksResets
    def self.instance
      @instance ||= new
    end

    def reset_needed!
      @reset_needed = true
    end

    def reset_state_if_needed(transactional_server)
      if @reset_needed
        ResetsState.new.call(transactional_server: transactional_server)
        @reset_needed = false
      end
    end

    private

    def initialize
      @reset_needed = false
    end
  end
end
