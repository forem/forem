module Rpush
  module Daemon
    module Pushy
      class Delivery < Rpush::Daemon::Delivery
        include MultiJsonHelper

        attr_reader :http, :notification, :batch, :pushy_uri

        def initialize(app, http, notification, batch)
          @http = http
          @notification = notification
          @batch = batch
          @pushy_uri = URI.parse("https://api.pushy.me/push?api_key=#{app.api_key}")
        end

        def perform
          response = send_request
          process_response(response)
        rescue SocketError => error
          mark_retryable(notification, Time.now + 10.seconds, error)
          raise
        rescue StandardError => error
          mark_failed(error)
          raise
        ensure
          batch.notification_processed
        end

        private

        def send_request
          post = Net::HTTP::Post.new(pushy_uri)
          post.content_type = 'application/json'
          post.body = notification.to_json
          http.request(pushy_uri, post)
        end

        def process_response(response)
          case response.code.to_i
          when 200
            process_delivery(response)
          when 429, 500, 502, 503, 504
            retry_delivery(response)
          else
            fail_delivery(response)
          end
        end

        def process_delivery(response)
          mark_delivered
          body = multi_json_load(response.body)
          external_device_id = body['id']
          notification.external_device_id = external_device_id
          Rpush::Daemon.store.update_notification(notification)
          log_info("#{notification.id} received an external id=#{external_device_id}")
        end

        def retry_delivery(response)
          time = deliver_after_header(response)
          if time
            mark_retryable(notification, time)
          else
            mark_retryable_exponential(notification)
          end
          log_warn("Pushy responded with a #{response.code} error. #{retry_message}")
        end

        def deliver_after_header(response)
          Rpush::Daemon::RetryHeaderParser.parse(response.header['retry-after'])
        end

        def retry_message
          deliver_after = notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')
          "Notification #{notification.id} will be retried after #{deliver_after} (retry #{notification.retries})."
        end

        def fail_delivery(response)
          fail_message = fail_message(response)
          log_error("#{notification.id} failed: #{fail_message}")
          fail Rpush::DeliveryError.new(response.code.to_i, notification.id, fail_message)
        end

        def fail_message(response)
          body = multi_json_load(response.body)
          body['error'] || Rpush::Daemon::HTTP_STATUS_CODES[response.code.to_i]
        end
      end
    end
  end
end
