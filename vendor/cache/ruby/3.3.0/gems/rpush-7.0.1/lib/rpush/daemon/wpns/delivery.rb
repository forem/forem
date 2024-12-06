module Rpush
  module Daemon
    module Wpns
      # http://msdn.microsoft.com/en-us/library/windowsphone/develop/ff941100%28v=vs.105%29.aspx
      class Delivery < Rpush::Daemon::Delivery
        FAILURE_MESSAGES = {
          400 => 'Bad XML or malformed notification URI.',
          401 => 'Unauthorized to send a notification to this app.'
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
          when 406
            not_acceptable
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
          when ["Received"]
            mark_delivered
            log_info("#{@notification.id} sent successfully")
          when ["QueueFull"]
            mark_retryable(@notification, Time.now + (60 * 10))
            log_warn("#{@notification.id} cannot be sent. The Queue is full.")
          when ["Suppressed"]
            handle_failure(200, "Notification was received but suppressed by the service.")
          end
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
          body = notification_to_xml
          post = Net::HTTP::Post.new(URI.parse(@notification.uri).path, "Content-Length" => body.length.to_s,
                                                                        "Content-Type" => "text/xml",
                                                                        "X-WindowsPhone-Target" => "toast",
                                                                        "X-NotificationClass" => '2')
          post.body = body
          @http.request(URI.parse(@notification.uri), post)
        end

        def status_from_response(response)
          headers = response.to_hash
          {
            notification:         headers["x-notificationstatus"],
            notification_channel: headers["x-subscriptionstatus"],
            device_connection:    headers["x-deviceconnectionstatus"]
          }
        end

        def notification_to_xml
          title = clean_param_string(@notification.data['title']) if @notification.data['title'].present?
          body = clean_param_string(@notification.data['body']) if @notification.data['body'].present?
          param = clean_param_string(@notification.data['param']) if @notification.data['param'].present?
          "<?xml version=\"1.0\" encoding=\"utf-8\"?>
           <wp:Notification xmlns:wp=\"WPNotification\">
             <wp:Toast>
               <wp:Text1>#{title}</wp:Text1>
               <wp:Text2>#{body}</wp:Text2>
               <wp:Param>#{param}</wp:Param>
             </wp:Toast>
           </wp:Notification>"
        end

        def clean_param_string(string)
          string.gsub(/&/, "&amp;").gsub(/</, "&lt;") \
            .gsub(/>/, "&gt;").gsub(/'/, "&apos;").gsub(/"/, "&quot;")
        end
      end
    end
  end
end
