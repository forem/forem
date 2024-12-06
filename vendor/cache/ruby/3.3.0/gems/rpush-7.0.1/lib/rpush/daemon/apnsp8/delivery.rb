module Rpush
  module Daemon
    module Apnsp8
      # https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingwithAPNs.html

      HTTP2_HEADERS_KEY = 'headers'

      class Delivery < Rpush::Daemon::Delivery
        RETRYABLE_CODES = [ 429, 500, 503 ]
        CLIENT_JOIN_TIMEOUT = 60
        DEFAULT_MAX_CONCURRENT_STREAMS = 100

        def initialize(app, http2_client, token_provider, batch)
          @app = app
          @client = http2_client
          @batch = batch
          @first_push = true
          @token_provider = token_provider
        end

        def perform
          @batch.each_notification do |notification|
            prepare_async_post(notification)
          end

          # Send all preprocessed requests at once
          @client.join(timeout: CLIENT_JOIN_TIMEOUT)
        rescue NetHttp2::AsyncRequestTimeout => error
          mark_batch_retryable(Time.now + 10.seconds, error)
          @client.close
          raise
        rescue Errno::ECONNREFUSED, SocketError, HTTP2::Error::StreamLimitExceeded => error
          # TODO restart connection when StreamLimitExceeded
          mark_batch_retryable(Time.now + 10.seconds, error)
          raise
        rescue StandardError => error
          mark_batch_failed(error)
          raise
        ensure
          @batch.all_processed
        end

        protected
        ######################################################################

        def prepare_async_post(notification)
          response = {}

          request = build_request(notification)
          http_request = @client.prepare_request(:post, request[:path],
            body:    request[:body],
            headers: request[:headers]
          )

          http_request.on(:headers) do |hdrs|
            response[:code] = hdrs[':status'].to_i
          end

          http_request.on(:body_chunk) do |body_chunk|
            next unless body_chunk.present?

            response[:failure_reason] = JSON.parse(body_chunk)['reason']
          end

          http_request.on(:close) { handle_response(notification, response) }

          if @first_push
            @first_push = false
            @client.call_async(http_request)
          else
            delayed_push_async(http_request)
          end
        end

        def delayed_push_async(http_request)
          until streams_available? do
            sleep 0.001
          end
          @client.call_async(http_request)
        end

        def streams_available?
          remote_max_concurrent_streams - @client.stream_count > 0
        end

        def remote_max_concurrent_streams
          # 0x7fffffff is the default value from http-2 gem (2^31)
          if @client.remote_settings[:settings_max_concurrent_streams] == 0x7fffffff
            # Ideally we'd fall back to `#local_settings` here, but `NetHttp2::Client`
            # doesn't expose that attr from the `HTTP2::Client` it wraps. Instead, we
            # chose a hard-coded value matching the default local setting from the
            # `HTTP2::Client` class
            DEFAULT_MAX_CONCURRENT_STREAMS
          else
            @client.remote_settings[:settings_max_concurrent_streams]
          end
        end

        def handle_response(notification, response)
          code = response[:code]
          case code
          when 200
            ok(notification)
          when *RETRYABLE_CODES
            service_unavailable(notification, response)
          else
            reflect(:notification_id_failed,
              @app,
              notification.id, code,
              response[:failure_reason])
            @batch.mark_failed(notification, response[:code], response[:failure_reason])
            failed_message_to_log(notification, response)
          end
        end

        def ok(notification)
          log_info("#{notification.id} sent to #{notification.device_token}")
          @batch.mark_delivered(notification)
        end

        def service_unavailable(notification, response)
          @batch.mark_retryable(notification, Time.now + 10.seconds)
          # Logs should go last as soon as we need to initialize
          # retry time to display it in log
          failed_message_to_log(notification, response)
          retry_message_to_log(notification)
        end

        def build_request(notification)
          {
            path:    "/3/device/#{notification.device_token}",
            headers: prepare_headers(notification),
            body:    prepare_body(notification)
          }
        end

        def prepare_body(notification)
          hash = notification.as_json.except(HTTP2_HEADERS_KEY)
          JSON.dump(hash).force_encoding(Encoding::BINARY)
        end

        def prepare_headers(notification)
          jwt_token = @token_provider.token

          headers = {}

          headers['content-type'] = 'application/json'
          headers['apns-expiration'] = '0'
          headers['apns-priority'] = '10'
          headers['apns-topic'] = @app.bundle_id
          headers['authorization'] = "bearer #{jwt_token}"
          headers['apns-push-type'] = 'background' if notification.content_available?

          headers.merge notification_data(notification)[HTTP2_HEADERS_KEY] || {}
        end

        def notification_data(notification)
          notification.data || {}
        end

        def retry_message_to_log(notification)
          log_warn("Notification #{notification.id} will be retried after "\
            "#{notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')} "\
            "(retry #{notification.retries}).")
        end

        def failed_message_to_log(notification, response)
          log_error("Notification #{notification.id} failed, "\
            "#{response[:code]}/#{response[:failure_reason]}")
        end
      end
    end
  end
end
