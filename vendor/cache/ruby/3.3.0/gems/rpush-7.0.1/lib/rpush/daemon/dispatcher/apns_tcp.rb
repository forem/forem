module Rpush
  module Daemon
    module Dispatcher
      class ApnsTcp < Rpush::Daemon::Dispatcher::Tcp
        include Loggable
        include Reflectable

        SELECT_TIMEOUT = 10
        ERROR_TUPLE_BYTES = 6
        APNS_ERRORS = {
          1 => 'Processing error',
          2 => 'Missing device token',
          3 => 'Missing topic',
          4 => 'Missing payload',
          5 => 'Missing token size',
          6 => 'Missing topic size',
          7 => 'Missing payload size',
          8 => 'Invalid device token',
          10 => 'APNs closed connection (possible maintenance)',
          255 => 'None (unknown error)'
        }

        def initialize(*args)
          super
          @dispatch_mutex = Mutex.new
          @stop_error_receiver = false
          @connection.on_connect { start_error_receiver }
        end

        def dispatch(payload)
          @dispatch_mutex.synchronize do
            @delivery_class.new(@app, @connection, payload.batch).perform
            record_batch(payload.batch)
          end
        end

        def cleanup
          if Rpush.config.push
            # In push mode only a single batch is sent, followed by immediate shutdown.
            # Allow the error receiver time to handle any errors.
            @reconnect_disabled = true
            sleep 1
          end

          @stop_error_receiver = true
          super
          @error_receiver_thread.join if @error_receiver_thread
        rescue StandardError => e
          log_error(e)
          reflect(:error, e)
        ensure
          @error_receiver_thread = nil
        end

        private

        def start_error_receiver
          @error_receiver_thread = Thread.new do
            check_for_error until @stop_error_receiver
            Rpush::Daemon.store.release_connection
          end
        end

        def delivered_buffer
          @delivered_buffer ||= RingBuffer.new(Rpush.config.batch_size * 10)
        end

        def record_batch(batch)
          batch.each_delivered do |notification|
            delivered_buffer << notification.id
          end
        end

        def check_for_error
          begin
            # On Linux, select returns nil from a dropped connection.
            # On OS X, Errno::EBADF is raised following a Errno::EADDRNOTAVAIL from the write call.
            return unless @connection.select(SELECT_TIMEOUT)
            tuple = @connection.read(ERROR_TUPLE_BYTES)
          rescue *TcpConnection::TCP_ERRORS
            reconnect unless @stop_error_receiver
            return
          end

          @dispatch_mutex.synchronize { handle_error_response(tuple) }
        rescue StandardError => e
          log_error(e)
        end

        def handle_error_response(tuple)
          if tuple
            _, code, notification_id = tuple.unpack('ccN')
            handle_error(code, notification_id)
          else
            handle_disconnect
          end

          if Rpush.config.push
            # Only attempt to handle a single error in Push mode.
            @stop_error_receiver = true
            return
          end

          reconnect
        ensure
          delivered_buffer.clear
        end

        def reconnect
          return if @reconnect_disabled
          log_error("Lost connection to #{@connection.host}:#{@connection.port}, reconnecting...")
          @connection.reconnect_with_rescue
        end

        def handle_disconnect
          log_error("The APNs disconnected before any notifications could be delivered. This usually indicates you are using an invalid certificate.") if delivered_buffer.size == 0
        end

        def handle_error(code, notification_id)
          notification_id = Rpush::Daemon.store.translate_integer_notification_id(notification_id)
          failed_pos = delivered_buffer.index(notification_id)
          description = description_for_code(code)
          log_error("Notification #{notification_id} failed with error: " + description)
          Rpush::Daemon.store.mark_ids_failed([notification_id], code, description, Time.now)
          reflect(:notification_id_failed, @app, notification_id, code, description)

          if failed_pos
            retry_ids = delivered_buffer[(failed_pos + 1)..-1]
            retry_notification_ids(retry_ids, notification_id)
          elsif delivered_buffer.size > 0
            log_error("Delivery sequence unknown for notifications following #{notification_id}.")
          end
        end

        def description_for_code(code)
          APNS_ERRORS[code.to_i] ? "#{APNS_ERRORS[code.to_i]} (#{code})" : "Unknown error code #{code.inspect}. Possible Rpush bug?"
        end

        def retry_notification_ids(ids, notification_id)
          return if ids.size == 0

          now = Time.now
          Rpush::Daemon.store.mark_ids_retryable(ids, now)
          notifications_str = 'Notification'
          notifications_str += 's' if ids.size > 1
          log_warn("#{notifications_str} #{ids.join(', ')} will be retried due to the failure of notification #{notification_id}.")
          ids.each { |id| reflect(:notification_id_will_retry, @app, id, now) }
        end
      end
    end
  end
end
