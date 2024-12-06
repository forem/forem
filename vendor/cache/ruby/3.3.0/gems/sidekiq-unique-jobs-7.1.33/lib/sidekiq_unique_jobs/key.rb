# frozen_string_literal: true

module SidekiqUniqueJobs
  # Key class wraps logic dealing with various lock keys
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Key
    #
    # @!attribute [r] digest
    #   @return [String] the digest key for which keys are created
    attr_reader :digest
    #
    # @!attribute [r] queued
    #   @return [String] the list key with queued job_id's
    attr_reader :queued
    #
    # @!attribute [r] primed
    #   @return [String] the list key with primed job_id's
    attr_reader :primed
    #
    # @!attribute [r] locked
    #   @return [String] the hash key with locked job_id's
    attr_reader :locked
    #
    # @!attribute [r] info
    #   @return [String] information about the lock
    attr_reader :info
    #
    # @!attribute [r] changelog
    #   @return [String] the zset with changelog entries
    attr_reader :changelog
    #
    # @!attribute [r] digests
    #   @return [String] the zset with locked digests
    attr_reader :digests
    #
    # @!attribute [r] expiring_digests
    #   @return [String] the zset with locked expiring_digests
    attr_reader :expiring_digests

    #
    # Initialize a new Key
    #
    # @param [String] digest the digest to use as key
    #
    def initialize(digest)
      @digest           = digest
      @queued           = suffixed_key("QUEUED")
      @primed           = suffixed_key("PRIMED")
      @locked           = suffixed_key("LOCKED")
      @info             = suffixed_key("INFO")
      @changelog        = CHANGELOGS
      @digests          = DIGESTS
      @expiring_digests = EXPIRING_DIGESTS
    end

    #
    # Provides the only important information about this keys
    #
    #
    # @return [String]
    #
    def to_s
      digest
    end

    # @see to_s
    def inspect
      digest
    end

    #
    # Compares keys by digest
    #
    # @param [Key] other the key to compare with
    #
    # @return [true, false]
    #
    def ==(other)
      digest == other.digest
    end

    #
    # Returns all keys as an ordered array
    #
    # @return [Array] an ordered array with all keys
    #
    def to_a
      [digest, queued, primed, locked, info, changelog, digests, expiring_digests]
    end

    private

    def suffixed_key(variable)
      "#{digest}:#{variable}"
    end
  end
end
