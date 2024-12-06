module Rpush
  module Daemon
    module Wns
      # https://msdn.microsoft.com/en-us/library/windows/apps/hh465435.aspx
      class Delivery < Rpush::Daemon::Delivery
        # Oauth2.0 token endpoint. This endpoint is used to request authorization tokens.
        WPN_TOKEN_URI = URI.parse('https://login.live.com/accesstoken.srf')

        # Data used to request authorization tokens.
        ACCESS_TOKEN_REQUEST_DATA = { "grant_type" => "client_credentials", "scope" => "notify.windows.com" }

        MAX_RETRIES = 14

        FAILURE_MESSAGES = {
          400 => 'One or more headers were specified incorrectly or conflict with another header.',
          401 => 'The cloud service did not present a valid authentication ticket. The OAuth ticket may be invalid.',
          403 => 'The cloud service is not authorized to send a notification to this URI even though they are authenticated.',
          404 => 'The channel URI is not valid or is not recognized by WNS.',
          405 => 'Invalid method (GET, CREATE); only POST (Windows or Windows Phone) or DELETE (Windows Phone only) is allowed.',
          406 => 'The cloud service exceeded its throttle limit.',
          410 => 'The channel expired.',
          413 => 'The notification payload exceeds the 5000 byte size limit.',
          500 => 'An internal failure caused notification delivery to fail.',
          503 => 'The server is currently unavailable.'
        }

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
        end

        def perform
          handle_response(do_post)
        rescue SocketError => error
          mark_retryable(@notification, Time.now + 10.seconds, error)
          raise
        rescue StandardError => error
          mark_failed(error)
          raise
        ensure
          @batch.notification_processed
        end

        private

        def handle_response(response)
          code = response.code.to_i
          case code
          when 200
            ok(response)
          when 401
            unauthorized
          when 404
            invalid_channel(code)
          when 406
            not_acceptable
          when 410
            invalid_channel(code)
          when 412
            precondition_failed
          when 503
            service_unavailable
          else
            handle_failure(code)
          end
        end

        def handle_failure(code, msg = nil)
          unless msg
            msg = FAILURE_MESSAGES.key?(code) ? FAILURE_MESSAGES[code] : Rpush::Daemon::HTTP_STATUS_CODES[code]
          end
          fail Rpush::DeliveryError.new(code, @notification.id, msg)
        end

        def ok(response)
          status = status_from_response(response)
          case status[:notification]
          when ["received"]
            mark_delivered
            log_info("#{@notification.id} sent successfully")
          when ["channelthrottled"]
            mark_retryable(@notification, Time.now + (60 * 10))
            log_warn("#{@notification.id} cannot be sent. The Queue is full.")
          when ["dropped"]
            log_error("#{@notification.id} was dropped. Headers: #{status}")
            handle_failure(200, "Notification was received but suppressed by the service (#{status[:error_description]}).")
          end
        end

        def unauthorized
          @notification.app.access_token = nil
          Rpush::Daemon.store.update_app(@notification.app)
          if @notification.retries < MAX_RETRIES
            retry_notification("Token invalid.")
          else
            msg = "Notification failed to be delivered in #{MAX_RETRIES} retries."
            mark_failed(Rpush::DeliveryError.new(nil, @notification.id, msg))
          end
        end

        def invalid_channel(code, msg = nil)
          unless msg
            msg = FAILURE_MESSAGES.key?(code) ? FAILURE_MESSAGES[code] : Rpush::Daemon::HTTP_STATUS_CODES[code]
          end
          reflect(:wns_invalid_channel, @notification, @notification.uri, "#{code}. #{msg}")
          handle_failure(code, msg)
        end

        def not_acceptable
          retry_notification("Per-day throttling limit reached.")
        end

        def precondition_failed
          retry_notification("Device unreachable.")
        end

        def service_unavailable
          mark_retryable_exponential(@notification)
          log_warn("Service Unavailable. " + retry_message)
        end

        def retry_message
          "Notification #{@notification.id} will be retried after #{@notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')} (retry #{@notification.retries})."
        end

        def retry_notification(reason)
          deliver_after = Time.now + (60 * 60)
          mark_retryable(@notification, deliver_after)
          log_warn("#{reason} " + retry_message)
        end

        def do_post
          post = PostRequest.create(@notification, access_token)
          @http.request(URI.parse(@notification.uri), post)
        end

        def status_from_response(response)
          headers = response.to_hash.each_with_object({}) { |e, a| a[e[0].downcase] = e[1] }
          {
            notification:         headers["x-wns-status"],
            device_connection:    headers["x-wns-deviceconnectionstatus"],
            msg_id:               headers["x-wns-msg-id"],
            error_description:    headers["x-wns-error-description"],
            debug_trace:          headers["x-wns-debug-trace"]
          }
        end

        def access_token
          if @notification.app.access_token.nil? || @notification.app.access_token_expired?
            post = Net::HTTP::Post.new(WPN_TOKEN_URI.path, 'Content-Type' => 'application/x-www-form-urlencoded')
            post.set_form_data(ACCESS_TOKEN_REQUEST_DATA.merge('client_id' => @notification.app.client_id, 'client_secret' => @notification.app.client_secret))

            handle_access_token(@http.request(WPN_TOKEN_URI, post))
          end

          @notification.app.access_token
        end

        def handle_access_token(response)
          if response.code.to_i == 200
            update_access_token(JSON.parse(response.body))
            Rpush::Daemon.store.update_app(@notification.app)
            log_info("WNS access token updated: token = #{@notification.app.access_token}, expires = #{@notification.app.access_token_expiration}")
          else
            log_warn("Could not retrieve access token from WNS: #{response.body}")
          end
        end

        def update_access_token(data)
          @notification.app.access_token = data['access_token']
          @notification.app.access_token_expiration = Time.now + data['expires_in'].to_i
        end
      end
    end
  end
end
