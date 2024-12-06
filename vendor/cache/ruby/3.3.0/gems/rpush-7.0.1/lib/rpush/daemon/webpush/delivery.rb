# frozen_string_literal: true

require "webpush"

module Rpush
  module Daemon
    module Webpush

      # Webpush::Request handles all the encryption / signing.
      # We just override #perform to inject the http instance that is managed
      # by Rpush.
      #
      class Request < ::Webpush::Request
        def perform(http)
          req = Net::HTTP::Post.new(uri.request_uri, headers)
          req.body = body
          http.request(uri, req)
        end
      end

      class Delivery < Rpush::Daemon::Delivery

        OK = [ 200, 201, 202 ].freeze
        TEMPORARY_FAILURES = [ 429, 500, 502, 503, 504 ].freeze

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
        end

        def perform
          response = send_request
          process_response response
        rescue SocketError, SystemCallError => error
          mark_retryable(@notification, Time.now + 10.seconds, error)
          raise
        rescue StandardError => error
          mark_failed(error)
          raise
        ensure
          @batch.notification_processed
        end

        private

        def send_request
          # The initializer is inherited from Webpush::Request and looks like
          # this:
          #
          # initialize(message: '', subscription:, vapid:, **options)
          #
          # where subscription is a hash of :endpoint and :keys, and vapid
          # holds the vapid public and private keys and the :subject (which is
          # an email address).
          Request.new(
            message: @notification.message,
            subscription: @notification.subscription,
            vapid: @app.vapid,
            ttl: @notification.time_to_live,
            urgency: @notification.urgency
          ).perform(@http)
        end

        def process_response(response)
          case response.code.to_i
          when *OK
            mark_delivered
          when *TEMPORARY_FAILURES
            retry_delivery(response)
          else
            fail_delivery(response)
          end
        end

        def retry_delivery(response)
          time = deliver_after_header(response)
          if time
            mark_retryable(@notification, time)
          else
            mark_retryable_exponential(@notification)
          end
          log_info("Webpush endpoint responded with a #{response.code} error. #{retry_message}")
        end

        def fail_delivery(response)
          fail_message = fail_message(response)
          log_error("#{@notification.id} failed: #{fail_message}")
          fail Rpush::DeliveryError.new(response.code.to_i, @notification.id, fail_message)
        end

        def deliver_after_header(response)
          Rpush::Daemon::RetryHeaderParser.parse(response.header['retry-after'])
        end

        def retry_message
          deliver_after = @notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')
          "Notification #{@notification.id} will be retried after #{deliver_after} (retry #{@notification.retries})."
        end

        def fail_message(response)
          msg = Rpush::Daemon::HTTP_STATUS_CODES[response.code.to_i]
          if explanation = response.body.to_s[0..200].presence
            msg += ": #{explanation}"
          end
          msg
        end

      end
    end
  end
end

