module Algolia
  class UserAgent
    attr_accessor :value

    @@value = Defaults::USER_AGENT

    # Set the value of the UserAgent
    #
    def self.value
      @@value
    end

    # Resets the value of the UserAgent
    #
    def self.reset_to_default
      @@value = Defaults::USER_AGENT
    end

    # Adds a segment to the UserAgent
    #
    def self.add(segment, version)
      @@value += format('; %<segment>s (%<version>s)', segment: segment, version: version)
    end
  end
end
