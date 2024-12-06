# frozen_string_literal: true

require_relative 'core/extensions'

# We must load core extensions to make certain global APIs
# accessible: both for Datadog features and the core itself.
module Datadog
  # Common, lower level, internal code used (or usable) by two or more
  # products. It is a dependency of each product. Contrast with Datadog::Kit
  # for higher-level features.
  module Core
    class << self
      # Records the occurrence of a deprecated operation in this library.
      #
      # Currently, these operations are logged to `Datadog.logger` at `warn` level.
      #
      # `disallowed_next_major` adds a message informing that the deprecated operation
      # won't be allowed in the next major release.
      #
      # @yieldreturn [String] a String with the lazily evaluated deprecation message.
      # @param [Boolean] disallowed_next_major whether this deprecation will be enforced in the next major release.
      def log_deprecation(disallowed_next_major: true)
        Datadog.logger.warn do
          message = yield
          message += ' This will be enforced in the next major release.' if disallowed_next_major
          message
        end
        nil
      end
    end
  end

  extend Core::Extensions

  # Add shutdown hook:
  # Ensures the Datadog components have a chance to gracefully
  # shut down and cleanup before terminating the process.
  at_exit do
    if Interrupt === $! # rubocop:disable Style/SpecialGlobalVars is process terminating due to a ctrl+c or similar?
      Datadog.send(:handle_interrupt_shutdown!)
    else
      Datadog.shutdown!
    end
  end
end
