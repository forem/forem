module Rpush
  module Daemon
    module Gcm
      # https://firebase.google.com/docs/cloud-messaging/server
      class Delivery < Rpush::Daemon::Delivery
        include MultiJsonHelper

        host = 'https://fcm.googleapis.com'
        FCM_URI = URI.parse("#{host}/fcm/send")
        UNAVAILABLE_STATES = %w(Unavailable BadGateway InternalServerError)
        INVALID_REGISTRATION_ID_STATES = %w(InvalidRegistration MismatchSenderId NotRegistered InvalidPackageName)

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

        protected

        def handle_response(response)
          case response.code.to_i
          when 200
            ok(response)
          when 400
            bad_request
          when 401
            unauthorized
          when 500
            internal_server_error(response)
          when 502
            bad_gateway(response)
          when 503
            service_unavailable(response)
          when 500..599
            other_5xx_error(response)
          else
            fail Rpush::DeliveryError.new(response.code.to_i, @notification.id, Rpush::Daemon::HTTP_STATUS_CODES[response.code.to_i])
          end
        end

        def ok(response)
          results = process_response(response)
          handle_successes(results.successes)

          if results.failures.any?
            handle_failures(results.failures, response)
          else
            mark_delivered
            log_info("#{@notification.id} sent to #{@notification.registration_ids.join(', ')}")
          end
        end

        def process_response(response)
          body = multi_json_load(response.body)
          results = Results.new(body['results'], @notification.registration_ids)
          results.process(invalid: INVALID_REGISTRATION_ID_STATES, unavailable: UNAVAILABLE_STATES)
          results
        end

        def handle_successes(successes)
          successes.each do |result|
            reflect(:gcm_delivered_to_recipient, @notification, result[:registration_id])
            next unless result.key?(:canonical_id)
            reflect(:gcm_canonical_id, result[:registration_id], result[:canonical_id])
          end
        end

        def handle_failures(failures, response)
          if failures[:unavailable].count == @notification.registration_ids.count
            retry_delivery(@notification, response)
            log_warn("All recipients unavailable. #{retry_message}")
          else
            if failures[:unavailable].any?
              unavailable_idxs = failures[:unavailable].map { |result| result[:index] }
              new_notification = create_new_notification(response, unavailable_idxs)
              failures.description += " #{unavailable_idxs.join(', ')} will be retried as notification #{new_notification.id}."
            end
            handle_errors(failures)
            fail Rpush::DeliveryError.new(nil, @notification.id, failures.description)
          end
        end

        def handle_errors(failures)
          failures.each do |result|
            reflect(:gcm_failed_to_recipient, @notification, result[:error], result[:registration_id])
          end
          failures[:invalid].each do |result|
            reflect(:gcm_invalid_registration_id, @app, result[:error], result[:registration_id])
          end
        end

        def create_new_notification(response, unavailable_idxs)
          attrs = { 'app_id' => @notification.app_id, 'collapse_key' => @notification.collapse_key, 'delay_while_idle' => @notification.delay_while_idle }
          registration_ids = @notification.registration_ids.values_at(*unavailable_idxs)
          Rpush::Daemon.store.create_gcm_notification(attrs, @notification.data,
                                                      registration_ids, deliver_after_header(response), @app)
        end

        def bad_request
          fail Rpush::DeliveryError.new(400, @notification.id, 'GCM failed to parse the JSON request. Possibly an Rpush bug, please open an issue.')
        end

        def unauthorized
          fail Rpush::DeliveryError.new(401, @notification.id, 'Unauthorized, check your App auth_key.')
        end

        def internal_server_error(response)
          retry_delivery(@notification, response)
          log_warn("GCM responded with an Internal Error. " + retry_message)
        end

        def bad_gateway(response)
          retry_delivery(@notification, response)
          log_warn("GCM responded with a Bad Gateway Error. " + retry_message)
        end

        def service_unavailable(response)
          retry_delivery(@notification, response)
          log_warn("GCM responded with an Service Unavailable Error. " + retry_message)
        end

        def other_5xx_error(response)
          retry_delivery(@notification, response)
          log_warn("GCM responded with a 5xx Error. " + retry_message)
        end

        def deliver_after_header(response)
          Rpush::Daemon::RetryHeaderParser.parse(response.header['retry-after'])
        end

        def retry_delivery(notification, response)
          time = deliver_after_header(response)
          if time
            mark_retryable(notification, time)
          else
            mark_retryable_exponential(notification)
          end
        end

        def retry_message
          "Notification #{@notification.id} will be retried after #{@notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')} (retry #{@notification.retries})."
        end

        def do_post
          post = Net::HTTP::Post.new(FCM_URI.path, 'Content-Type'  => 'application/json',
                                                   'Authorization' => "key=#{@app.auth_key}")
          post.body = @notification.as_json.to_json
          @http.request(FCM_URI, post)
        end
      end

      class Results
        attr_reader :successes, :failures

        def initialize(results_data, registration_ids)
          @results_data = results_data
          @registration_ids = registration_ids
        end

        def process(failure_partitions = {}) # rubocop:disable Metrics/AbcSize
          @successes = []
          @failures = Failures.new
          failure_partitions.each_key do |category|
            failures[category] = []
          end

          @results_data.each_with_index do |result, index|
            entry = {
              registration_id: @registration_ids[index],
              index: index
            }
            if result['message_id']
              entry[:canonical_id] = result['registration_id'] if result['registration_id'].present?
              successes << entry
            elsif result['error']
              entry[:error] = result['error']
              failures << entry
              failure_partitions.each do |category, error_states|
                failures[category] << entry if error_states.include?(result['error'])
              end
            end
          end
          failures.all_failed = failures.count == @registration_ids.count
        end
      end

      class Failures < Hash
        include Enumerable
        attr_writer :all_failed, :description

        def initialize
          super[:all] = []
        end

        def each
          self[:all].each { |x| yield x }
        end

        def <<(item)
          self[:all] << item
        end

        def description
          @description ||= describe
        end

        def any?
          self[:all].any?
        end

        private

        def describe
          if @all_failed
            error_description = "Failed to deliver to all recipients."
          else
            index_list = map { |item| item[:index] }
            error_description = "Failed to deliver to recipients #{index_list.join(', ')}."
          end

          error_list = map { |item| item[:error] }
          error_description + " Errors: #{error_list.join(', ')}."
        end
      end
    end
  end
end
