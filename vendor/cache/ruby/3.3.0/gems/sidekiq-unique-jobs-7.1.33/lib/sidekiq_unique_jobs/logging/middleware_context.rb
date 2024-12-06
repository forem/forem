# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Provides the sidekiq middleware that makes the gem work
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  module Logging
    #
    # Context aware logging for Sidekiq Middlewares
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module Middleware
      include Logging

      def self.included(base)
        base.class_eval do
          extend Logging::Middleware
        end
      end

      #
      # Provides a logging context for Sidekiq Middlewares
      #
      #
      # @return [Hash] when logger responds to `:with_context`
      # @return [String] when logger does not responds to `:with_context`
      #
      def logging_context
        middleware = is_a?(SidekiqUniqueJobs::Middleware::Client) ? :client : :server
        digest     = item[LOCK_DIGEST]
        lock_type  = item[LOCK]

        if logger_context_hash?
          { "uniquejobs" => middleware, lock_type => digest }
        else
          "uniquejobs-#{middleware} #{"DIG-#{digest}" if digest}"
        end
      end
    end
  end
end
