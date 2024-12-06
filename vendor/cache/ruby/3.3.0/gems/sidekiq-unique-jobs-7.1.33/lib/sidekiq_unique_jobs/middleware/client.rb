# frozen_string_literal: true

module SidekiqUniqueJobs
  module Middleware
    # The unique sidekiq middleware for the client push
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Client
      include Sidekiq::ClientMiddleware if defined?(Sidekiq::ClientMiddleware)

      # prepend "SidekiqUniqueJobs::Middleware"
      # @!parse prepends SidekiqUniqueJobs::Middleware
      prepend SidekiqUniqueJobs::Middleware
      # includes "SidekiqUniqueJobs::Reflectable"
      # @!parse include SidekiqUniqueJobs::Reflectable
      include SidekiqUniqueJobs::Reflectable

      # Calls this client middleware
      #   Used from Sidekiq.process_single
      #
      # @see SidekiqUniqueJobs::Middleware#call
      #
      # @see https://github.com/mperham/sidekiq/wiki/Job-Format
      # @see https://github.com/mperham/sidekiq/wiki/Middleware
      #
      # @yield when uniqueness is disable
      # @yield when the lock is successful
      def call(*, &block)
        lock(&block)
      end

      private

      def lock
        lock_instance.lock do
          reflect(:locked, item)
          return yield
        end
      end
    end
  end
end
