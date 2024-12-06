require 'forwardable'
require 'net/http'

require 'honeybadger/logging'

module Honeybadger
  # A concurrent queue to notify the backend.
  # @api private
  class Worker
    extend Forwardable

    include Honeybadger::Logging::Helper

    # Sub-class thread so we have a named thread (useful for debugging in Thread.list).
    class Thread < ::Thread; end

    # Used to signal the worker to shutdown.
    SHUTDOWN = :__hb_worker_shutdown!

    # The base number for the exponential backoff formula when calculating the
    # throttle interval. `1.05 ** throttle` will reach an interval of 2 minutes
    # after around 100 429 responses from the server.
    BASE_THROTTLE = 1.05

    def initialize(config)
      @config = config
      @throttle = 0
      @throttle_interval = 0
      @mutex = Mutex.new
      @marker = ConditionVariable.new
      @queue = Queue.new
      @shutdown = false
      @start_at = nil
      @pid = Process.pid
    end

    def push(msg)
      return false unless start

      if queue.size >= config.max_queue_size
        warn { sprintf('Unable to report error; reached max queue size of %s. id=%s', queue.size, msg.id) }
        return false
      end

      queue.push(msg)
    end

    def send_now(msg)
      handle_response(msg, notify_backend(msg))
    end

    def shutdown(force = false)
      d { 'shutting down worker' }

      mutex.synchronize do
        @shutdown = true
      end

      return true if force
      return true unless thread&.alive?

      if throttled?
        warn { sprintf('Unable to report %s error(s) to Honeybadger (currently throttled)', queue.size) } unless queue.empty?
        return true
      end

      info { sprintf('Waiting to report %s error(s) to Honeybadger', queue.size) } unless queue.empty?

      queue.push(SHUTDOWN)
      !!thread.join
    ensure
      queue.clear
      kill!
    end

    # Blocks until queue is processed up to this point in time.
    def flush
      mutex.synchronize do
        if thread && thread.alive?
          queue.push(marker)
          marker.wait(mutex)
        end
      end
    end

    def start
      return false unless can_start?

      mutex.synchronize do
        @shutdown = false
        @start_at = nil

        return true if thread&.alive?

        @pid = Process.pid
        @thread = Thread.new { run }
      end

      true
    end

    private

    attr_reader :config, :queue, :pid, :mutex, :marker, :thread, :throttle,
      :throttle_interval, :start_at

    def_delegator :config, :backend

    def shutdown?
      mutex.synchronize { @shutdown }
    end

    def suspended?
      mutex.synchronize { start_at && Time.now.to_i < start_at }
    end

    def can_start?
      return false if shutdown?
      return false if suspended?
      true
    end

    def throttled?
      mutex.synchronize { throttle > 0 }
    end

    def kill!
      d { 'killing worker thread' }

      if thread
        Thread.kill(thread)
        thread.join # Allow ensure blocks to execute.
      end

      true
    end

    def suspend(interval)
      mutex.synchronize do
        @start_at = Time.now.to_i + interval
        queue.clear
      end

      # Must be performed last since this may kill the current thread.
      kill!
    end

    def run
      begin
        d { 'worker started' }
        loop do
          case msg = queue.pop
          when SHUTDOWN then break
          when ConditionVariable then signal_marker(msg)
          else work(msg)
          end
        end
      ensure
        d { 'stopping worker' }
      end
    rescue Exception => e
      error {
        msg = "Error in worker thread (shutting down) class=%s message=%s\n\t%s"
        sprintf(msg, e.class, e.message.dump, Array(e.backtrace).join("\n\t"))
      }
    ensure
      release_marker
    end

    def work(msg)
      send_now(msg)

      if shutdown? && throttled?
        warn { sprintf('Unable to report %s error(s) to Honeybadger (currently throttled)', queue.size) } if queue.size > 1
        kill!
        return
      end

      sleep(throttle_interval)
    rescue StandardError => e
      error {
        msg = "Error in worker thread class=%s message=%s\n\t%s"
        sprintf(msg, e.class, e.message.dump, Array(e.backtrace).join("\n\t"))
      }
    end

    def notify_backend(payload)
      d { sprintf('worker notifying backend id=%s', payload.id) }
      backend.notify(:notices, payload)
    end

    def calc_throttle_interval
      ((BASE_THROTTLE ** throttle) - 1).round(3)
    end

    def inc_throttle
      mutex.synchronize do
        @throttle += 1
        @throttle_interval = calc_throttle_interval
        throttle
      end
    end

    def dec_throttle
      mutex.synchronize do
        return nil if throttle == 0
        @throttle -= 1
        @throttle_interval = calc_throttle_interval
        throttle
      end
    end

    def handle_response(msg, response)
      d { sprintf('worker response id=%s code=%s message=%s', msg.id, response.code, response.message.to_s.dump) }

      case response.code
      when 429, 503
        throttle = inc_throttle
        warn { sprintf('Error report failed: project is sending too many errors. id=%s code=%s throttle=%s interval=%s', msg.id, response.code, throttle, throttle_interval) }
      when 402
        warn { sprintf('Error report failed: payment is required. id=%s code=%s', msg.id, response.code) }
        suspend(3600)
      when 403
        warn { sprintf('Error report failed: API key is invalid. id=%s code=%s', msg.id, response.code) }
        suspend(3600)
      when 201
        if throttle = dec_throttle
          info { sprintf('Success ⚡ https://app.honeybadger.io/notice/%s id=%s code=%s throttle=%s interval=%s', msg.id, msg.id, response.code, throttle, throttle_interval) }
        else
          info { sprintf('Success ⚡ https://app.honeybadger.io/notice/%s id=%s code=%s', msg.id, msg.id, response.code) }
        end
      when :stubbed
        info { sprintf('Success ⚡ Development mode is enabled; this error will be reported if it occurs after you deploy your app. id=%s', msg.id) }
      when :error
        warn { sprintf('Error report failed: an unknown error occurred. code=%s error=%s', response.code, response.message.to_s.dump) }
      else
        warn { sprintf('Error report failed: unknown response from server. code=%s', response.code) }
      end
    end

    # Release the marker. Important to perform during cleanup when shutting
    # down, otherwise it could end up waiting indefinitely.
    def release_marker
      signal_marker(marker)
    end

    def signal_marker(marker)
      mutex.synchronize do
        marker.signal
      end
    end
  end
end
