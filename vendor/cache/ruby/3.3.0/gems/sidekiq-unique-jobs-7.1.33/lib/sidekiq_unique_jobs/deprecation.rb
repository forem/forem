# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class Deprecation provides logging of deprecations
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class Deprecation
    #
    # Mute warnings from this gem in a threaded context
    #
    #
    # @return [void] <description>
    #
    # @yieldreturn [void]
    def self.muted
      orig_val = Thread.current[:uniquejobs_mute_deprecations]
      Thread.current[:uniquejobs_mute_deprecations] = true
      yield
    ensure
      Thread.current[:uniquejobs_mute_deprecations] = orig_val
    end

    #
    # Check if deprecation warnings have been muted
    #
    #
    # @return [true,false]
    #
    def self.muted?
      Thread.current[:uniquejobs_mute_deprecations] == true
    end

    #
    # Warn about deprecation
    #
    # @param [String] msg a descriptive reason for why the deprecation
    #
    # @return [void]
    #
    def self.warn(msg)
      return if SidekiqUniqueJobs::Deprecation.muted?

      warn "DEPRECATION WARNING: #{msg}"
      nil
    end

    #
    # Warn about deprecation and provide a context
    #
    # @param [String] msg a descriptive reason for why the deprecation
    #
    # @return [void]
    #
    def self.warn_with_backtrace(msg)
      return if SidekiqUniqueJobs::Deprecation.muted?

      trace = "\n\nCALLED FROM:\n#{caller.join("\n")}"
      warn(msg + trace)

      nil
    end
  end
end
