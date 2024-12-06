# frozen_string_literal: true

require_relative 'worker'
require_relative 'client/capabilities'
require_relative 'client'
require_relative 'transport/http'
require_relative '../remote'
require_relative 'negotiation'

module Datadog
  module Core
    module Remote
      # Configures the HTTP transport to communicate with the agent
      # to fetch and sync the remote configuration
      class Component
        BARRIER_TIMEOUT = 1.0 # second

        attr_reader :client

        def initialize(settings, capabilities, agent_settings)
          transport_options = {}
          transport_options[:agent_settings] = agent_settings if agent_settings

          negotiation = Negotiation.new(settings, agent_settings)
          transport_v7 = Datadog::Core::Remote::Transport::HTTP.v7(**transport_options.dup)

          @barrier = Barrier.new(BARRIER_TIMEOUT)

          @client = Client.new(transport_v7, capabilities)
          healthy = false
          Datadog.logger.debug { "new remote configuration client: #{@client.id}" }

          @worker = Worker.new(interval: settings.remote.poll_interval_seconds) do
            unless healthy || negotiation.endpoint?('/v0.7/config')
              @barrier.lift

              next
            end

            begin
              @client.sync
              healthy ||= true
            rescue Client::SyncError => e
              Datadog.logger.error do
                "remote worker client sync error: #{e.message} location: #{Array(e.backtrace).first}. skipping sync"
              end
            rescue StandardError => e
              # In case of unexpected errors, reset the negotiation object
              # given external conditions have changed and the negotiation
              # negotiation object stores error logging state that should be reset.
              negotiation = Negotiation.new(settings, agent_settings)

              Datadog.logger.error do
                "remote worker error: #{e.class.name} #{e.message} location: #{Array(e.backtrace).first}. "\
                'reseting client state'
              end

              # client state is unknown, state might be corrupted
              @client = Client.new(transport_v7, capabilities)
              healthy = false
              Datadog.logger.debug { "new remote configuration client: #{@client.id}" }

              # TODO: bail out if too many errors?
            end

            @barrier.lift
          end
        end

        # Starts the Remote Configuration worker without waiting for first run
        def start
          @worker.start
        end

        # Is the Remote Configuration worker running?
        def started?
          @worker.started?
        end

        # If the worker is not initialized, initialize it.
        #
        # Then, waits for one client sync to be executed if `kind` is `:once`.
        def barrier(_kind)
          start
          @barrier.wait_once
        end

        def shutdown!
          @worker.stop
        end

        # Barrier provides a mechanism to fence execution until a condition happens
        class Barrier
          def initialize(timeout = nil)
            @once = false
            @timeout = timeout

            @mutex = Mutex.new
            @condition = ConditionVariable.new
          end

          # Wait for first lift to happen, otherwise don't wait
          def wait_once(timeout = nil)
            # TTAS (Test and Test-And-Set) optimisation
            # Since @once only ever goes from false to true, this is semantically valid
            return if @once

            begin
              @mutex.lock

              return if @once

              timeout ||= @timeout

              # rbs/core has a bug, timeout type is incorrectly ?Integer
              @condition.wait(@mutex, _ = timeout)
            ensure
              @mutex.unlock
            end
          end

          # Release all current waiters
          def lift
            @mutex.lock

            @once ||= true

            @condition.broadcast
          ensure
            @mutex.unlock
          end
        end

        class << self
          # Because the agent might not be available yet, we can't perform agent-specific checks yet, as they
          # would prevent remote configuration from ever running.
          #
          # Those checks are instead performed inside the worker loop.
          # This allows users to upgrade their agent while keeping their application running.
          def build(settings, agent_settings)
            return unless settings.remote.enabled

            new(settings, Client::Capabilities.new(settings), agent_settings)
          end
        end
      end
    end
  end
end
