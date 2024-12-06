# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Handles checking if a version is compliant with given constraint
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class VersionCheck
    PATTERN = /(?<operator1>[<>=]+)?\s?(?<version1>(\d+.?)+)(\s+&&\s+)?(?<operator2>[<>=]+)?\s?(?<version2>(\d+.?)+)?/m.freeze # rubocop:disable Layout/LineLength, Lint/MixedRegexpCaptureTypes

    #
    # Checks if a version is constraint is satisfied
    #
    # @example A satisfied constraint
    #   VersionCheck.satisfied?("5.0.0", ">= 4.0.0") #=> true
    #
    # @example An unsatisfied constraint
    #   VersionCheck.satisfied?("5.0.0", "<= 4.0.0") #=> false
    #
    #
    # @param [String] version a version string `5.0.0`
    # @param [String] constraint a version constraint `>= 5.0.0 <= 5.1.1`
    #
    # @return [true, false] <description>
    #
    def self.satisfied?(version, constraint)
      new(version, constraint).satisfied?
    end

    #
    # Checks if a version is constraint is unfulfilled
    #
    # @example A satisfied constraint
    #   VersionCheck.unfulfilled?("5.0.0", ">= 4.0.0") #=> false
    #
    # @example An unfulfilled constraint
    #   VersionCheck.unfulfilled?("5.0.0", "<= 4.0.0") #=> true
    #
    #
    # @param [String] version a version string `5.0.0`
    # @param [String] constraint a version constraint `>= 5.0.0 <= 5.1.1`
    #
    # @return [true, false] <description>
    #
    def self.unfulfilled?(version, constraint)
      !satisfied?(version, constraint)
    end

    #
    # @!attribute [r] version
    #   @return [String] a version string `5.0.0`
    attr_reader :version
    #
    # @!attribute [r] match
    #   @return [String] a version constraint `>= 5.0.0 <= 5.1.1`
    attr_reader :match

    #
    # Initialize a new VersionCheck instance
    #
    # @param [String] version a version string `5.0.0`
    # @param [String] constraint a version constraint `>= 5.0.0 <= 5.1.1`
    #
    def initialize(version, constraint)
      @version   = Gem::Version.new(version)
      @match     = PATTERN.match(constraint.to_s)

      raise ArgumentError, "A version (eg. 5.0) is required to compare against" unless @version
      raise ArgumentError, "At least one operator and version is required (eg. >= 5.1)" unless constraint
    end

    #
    # Checks if all constraints were met
    #
    #
    # @return [true,false]
    #
    def satisfied?
      constraints.all? do |expected, operator|
        compare(expected, operator)
      end
    end

    private

    def compare(expected, operator)
      Gem::Version.new(version).send(operator, Gem::Version.new(expected))
    end

    def constraints
      result = { version_one => operator_one }
      result[version_two] = operator_two if version_two

      result
    end

    def version_one
      match[:version1]
    end

    def operator_one
      match[:operator1]
    end

    def version_two
      match[:version2]
    end

    def operator_two
      match[:operator2]
    end
  end
end
