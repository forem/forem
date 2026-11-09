# rubocop:disable Metrics/BlockLength
require "rpush/daemon"

# Guard NetHttp2::Client against writing to a nil @socket when the background
# @socket_thread closes a disconnected APNs HTTP/2 socket mid-request, raising
# a retryable SocketError instead of `NoMethodError: undefined method 'write' for nil`.
if defined?(NetHttp2::Client)
  module NetHttp2NilSocketGuard
    private

    # Builds the underlying HTTP2::Client and guards frame writes against a nil
    # @socket when the background socket thread closes a disconnected stream.
    def h2
      @h2 ||= HTTP2::Client.new.tap do |h2|
        h2.on(:frame) do |bytes|
          @mutex.synchronize do
            raise SocketError, "Socket was remotely closed" if @socket.nil?

            @socket.write(bytes)
            @socket.flush

            @first_data_sent = true
          end
        end
      end
    end
  end
  NetHttp2::Client.prepend(NetHttp2NilSocketGuard)
end

# Treat transient APNs HTTP/2 socket disconnects (EPIPE / Broken pipe,
# ECONNRESET, ETIMEDOUT, IOError, EOFError, OpenSSL::SSL::SSLError) as retryable
# batch errors and reset the HTTP/2 client instead of permanently failing every
# notification in the batch.
if defined?(Rpush::Daemon::Apns2::Delivery)
  module RpushApns2TransientSocketRetry
    TRANSIENT_TRANSPORT_ERRORS = [
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      SocketError,
      IOError,
      EOFError,
      OpenSSL::SSL::SSLError,
    ].freeze

    # Sends all notifications in @batch over the HTTP/2 client, marking the
    # batch retryable and closing the client on transient transport disconnects.
    def perform
      @batch.each_notification do |notification|
        prepare_async_post(notification)
      end

      @client.join(timeout: self.class::CLIENT_JOIN_TIMEOUT)
    rescue NetHttp2::AsyncRequestTimeout, *TRANSIENT_TRANSPORT_ERRORS => e
      mark_batch_retryable(10.seconds.from_now, e)
      @client.close
      raise
    rescue StandardError => e
      mark_batch_failed(e)
      raise
    ensure
      @batch.all_processed
    end
  end
  Rpush::Daemon::Apns2::Delivery.prepend(RpushApns2TransientSocketRetry)
end

Rpush.configure do |config|
  # Supported clients are :active_record and :redis
  config.client = :redis

  # Options passed to Redis.new
  config.redis_options = { url: ENV.fetch("REDIS_RPUSH_URL") { ENV.fetch("REDIS_URL", nil) }, driver: :ruby }

  # Frequency in seconds to check for new notifications.
  config.push_poll = 2

  # The maximum number of notifications to load from the store every `push_poll` seconds.
  # If some notifications are still enqueued internally, Rpush will load the batch_size less
  # the number enqueued. An exception to this is if the service is able to receive multiple
  # notification payloads over the connection with a single write, such as APNs.
  config.batch_size = 100

  # Path to write PID file. Relative to current directory unless absolute.
  # config.pid_file = "tmp/rpush.pid"

  # Path to log file. Relative to current directory unless absolute.
  # config.log_file = "log/rpush.log"

  config.log_level = (defined?(Rails) && Rails.logger ? Rails.logger.level : Logger::Severity::INFO)

  # Define a custom logger.
  config.logger = Rails.logger

  # By default in foreground mode logs are directed both to the logger and to stdout.
  # If the logger goes to stdout, you can disable foreground logging to avoid duplication.
  config.foreground_logging = false

  # config.apns.feedback_receiver.enabled = true
  # config.apns.feedback_receiver.frequency = 60
end

Rpush.reflect do |on|
  # Called with a Rpush::Apns::Feedback instance when feedback is received
  # from the APNs that a notification has failed to be delivered.
  # Further notifications should not be sent to the device.
  # on.apns_feedback do |feedback|
  # end

  # Called when a notification is queued internally for delivery.
  # The internal queue for each app runner can be inspected:
  #
  # Rpush::Daemon::AppRunner.runners.each do |app_id, runner|
  #   runner.app
  #   runner.queue_size
  # end
  #
  # on.notification_enqueued do |notification|
  # end

  # Called when a notification is successfully delivered.
  on.notification_delivered do |notification|
    ForemStatsClient.increment(
      "push_notifications.delivered",
      tags: [
        "app_bundle:#{notification.app&.bundle_id}",
        "type:#{JSON.parse(notification.payload).dig('data', 'type') || 'unknown'}",
        "host:#{ENV.fetch('APP_DOMAIN', nil)}",
      ],
    )
  end

  # Called when notification delivery failed.
  # Call 'error_code' and 'error_description' on the notification for the cause.
  on.notification_failed do |notification|
    if notification.error_description == "BadDeviceToken"
      # When adding new platforms we'll need to check to only clear out devices
      # scoped to that specific platform. i.e. notification.class.to_s =~ /Apns.+::Notification/
      Device.ios.where(token: notification.device_token).destroy_all
    end

    transient_transport_failure = notification.error_code.nil? &&
      notification.error_description.to_s.match?(
        /Broken pipe|Connection reset|Socket was remotely closed|undefined method ['`]write' for nil/i,
      )

    if transient_transport_failure
      Rails.logger.warn(
        "[Rpush] Transient transport failure for notification #{notification.id}: #{notification.error_description}",
      )
    else
      msg = "error_description: #{notification.error_description}, error_code: #{notification.error_code}"
      Rails.error.report(StandardError.new(msg))
    end

    ForemStatsClient.increment(
      "push_notifications.errors",
      tags: [
        "app_bundle:#{notification.app&.bundle_id}",
        "error_code:#{notification.error_code}",
        "error_description:#{notification.error_description}",
        "host:#{ENV.fetch('APP_DOMAIN', nil)}",
      ],
    )
  end

  # Called when the notification delivery failed and only the notification ID
  # is present in memory.
  # on.notification_id_failed do |app, notification_id, error_code, error_description|
  # end

  # Called when a notification will be retried at a later date.
  # Call 'deliver_after' on the notification for the next delivery date
  # and 'retries' for the number of times this notification has been retried.
  # on.notification_will_retry do |notification|
  # end

  # Called when a notification will be retried and only the notification ID
  # is present in memory.
  # on.notification_id_will_retry do |app, notification_id, retry_after|
  # end

  # Called when a TCP connection is lost and will be reconnected.
  # on.tcp_connection_lost do |app, error|
  # end

  # Called for each recipient which successfully receives a notification. This
  # can occur more than once for the same notification when there are multiple
  # recipients.
  # on.gcm_delivered_to_recipient do |notification, registration_id|
  # end

  # Called for each recipient which fails to receive a notification. This
  # can occur more than once for the same notification when there are multiple
  # recipients. (do not handle invalid registration IDs here)
  # on.gcm_failed_to_recipient do |notification, error, registration_id|
  # end

  # Called when the GCM returns a canonical registration ID.
  # You will need to replace old_id with canonical_id in your records.
  # on.gcm_canonical_id do |old_id, canonical_id|
  # end

  # Called when the GCM returns a failure that indicates an invalid registration id.
  # You will need to delete the registration_id from your records.
  # on.gcm_invalid_registration_id do |app, error, registration_id|
  # end

  # Called when an SSL certificate will expire within 1 month.
  # Implement on.error to catch errors raised when the certificate expires.
  # on.ssl_certificate_will_expire do |app, expiration_time|
  # end

  # Called when an SSL certificate has been revoked.
  # on.ssl_certificate_revoked do |app, error|
  # end

  # Called when the ADM returns a canonical registration ID.
  # You will need to replace old_id with canonical_id in your records.
  # on.adm_canonical_id do |old_id, canonical_id|
  # end

  # Called when Failed to deliver to ADM. Check the 'reason' string for further
  # explanations.
  #
  # If the reason is the string 'Unregistered', you should remove
  # this registration id from your records.
  # on.adm_failed_to_recipient do |notification, registration_id, reason|
  # end

  # Called when Failed to deliver to WNS. Check the 'reason' string for further
  # explanations.
  # You should remove this uri from your records
  # on.wns_invalid_channel do |notification, uri, reason|
  # end

  # Called when an exception is raised.
  # on.error do |error|
  # end
end
# rubocop:enable Metrics/BlockLength
