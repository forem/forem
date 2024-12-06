# frozen_string_literal: true

module Datadog
  module Core
    module Remote
      # Worker executes a block every interval on a separate Thread
      class Worker
        def initialize(interval:, &block)
          @mutex = Mutex.new
          @thr = nil

          @starting = false
          @stopping = false
          @started = false

          @interval = interval
          raise ArgumentError, 'can not initialize a worker without a block' unless block

          @block = block
        end

        def start
          Datadog.logger.debug { 'remote worker starting' }

          acquire_lock

          return if @starting || @started

          @starting = true

          thread = Thread.new { poll(@interval) }
          thread.name = self.class.name unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3')
          @thr = thread

          @started = true
          @starting = false

          Datadog.logger.debug { 'remote worker started' }
        ensure
          release_lock
        end

        def stop
          Datadog.logger.debug { 'remote worker stopping' }

          acquire_lock

          @stopping = true

          thread = @thr

          if thread
            thread.kill
            thread.join
          end

          @started = false
          @stopping = false
          @thr = nil

          Datadog.logger.debug { 'remote worker stopped' }
        ensure
          release_lock
        end

        def started?
          @started
        end

        private

        def acquire_lock
          @mutex.lock
        end

        def release_lock
          @mutex.unlock
        end

        def poll(interval)
          loop do
            break unless @mutex.synchronize { @starting || @started }

            call

            sleep(interval)
          end
        end

        def call
          Datadog.logger.debug { 'remote worker perform' }

          @block.call
        end
      end
    end
  end
end
