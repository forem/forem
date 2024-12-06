module Rpush
  module Daemon
    module Store
      class Redis
        DEFAULT_MARK_OPTIONS = { persist: true }

        def app(app_id)
          Rpush::Client::Redis::App.find(app_id)
        end

        def all_apps
          Rpush::Client::Redis::App.all
        end

        def deliverable_notifications(limit)
          retryable_ids = retryable_notification_ids
          limit -= retryable_ids.size
          pending_ids = limit > 0 ? pending_notification_ids(limit) : []
          ids = retryable_ids + pending_ids
          ids.map { |id| find_notification_by_id(id) }.compact
        end

        def mark_delivered(notification, time, opts = {})
          opts = DEFAULT_MARK_OPTIONS.dup.merge(opts)
          notification.delivered = true
          notification.delivered_at = time
          notification.save!(validate: false) if opts[:persist]
        end

        def mark_batch_delivered(notifications)
          now = Time.now
          notifications.each { |n| mark_delivered(n, now) }
        end

        def mark_failed(notification, code, description, time, opts = {})
          opts = DEFAULT_MARK_OPTIONS.dup.merge(opts)
          notification.delivered = false
          notification.delivered_at = nil
          notification.failed = true
          notification.failed_at = time
          notification.error_code = code
          notification.error_description = description
          notification.save!(validate: false) if opts[:persist]
        end

        def mark_batch_failed(notifications, code, description)
          now = Time.now
          notifications.each { |n| mark_failed(n, code, description, now) }
        end

        def mark_ids_failed(ids, code, description, time)
          ids.each do |id|
            notification = find_notification_by_id(id)
            next unless notification

            mark_failed(notification, code, description, time)
          end
        end

        def mark_retryable(notification, deliver_after, opts = {})
          opts = DEFAULT_MARK_OPTIONS.dup.merge(opts)
          notification.delivered = false
          notification.delivered_at = nil
          notification.failed = false
          notification.failed_at = nil
          notification.retries += 1
          notification.deliver_after = deliver_after

          return unless opts[:persist]

          notification.save!(validate: false)
          namespace = Rpush::Client::Redis::Notification.absolute_retryable_namespace
          Modis.with_connection do |redis|
            redis.zadd(namespace, deliver_after.to_i, notification.id)
          end
        end

        def mark_batch_retryable(notifications, deliver_after)
          notifications.each { |n| mark_retryable(n, deliver_after) }
        end

        def mark_ids_retryable(ids, deliver_after)
          ids.each do |id|
            notification = find_notification_by_id(id)
            next unless notification

            mark_retryable(notification, deliver_after)
          end
        end

        def create_apns_feedback(failed_at, device_token, app)
          Rpush::Client::Redis::Apns::Feedback.create!(failed_at: failed_at, device_token: device_token, app_id: app.id)
        end

        def create_gcm_notification(attrs, data, registration_ids, deliver_after, app)
          notification = Rpush::Client::Redis::Gcm::Notification.new
          create_gcm_like_notification(notification, attrs, data, registration_ids, deliver_after, app)
        end

        def create_adm_notification(attrs, data, registration_ids, deliver_after, app)
          notification = Rpush::Client::Redis::Adm::Notification.new
          create_gcm_like_notification(notification, attrs, data, registration_ids, deliver_after, app)
        end

        def update_app(app)
          app.save!
        end

        def update_notification(notification)
          notification.save!
        end

        def release_connection
        end

        def reopen_log
        end

        def pending_delivery_count
          Modis.with_connection do |redis|
            pending = redis.zrange(Rpush::Client::Redis::Notification.absolute_pending_namespace, 0, -1)
            retryable = redis.zrangebyscore(Rpush::Client::Redis::Notification.absolute_retryable_namespace, 0, Time.now.to_i)

            pending.count + retryable.count
          end
        end

        def translate_integer_notification_id(id)
          id
        end

        private

        def find_notification_by_id(id)
          Rpush::Client::Redis::Notification.find(id)
        rescue Modis::RecordNotFound
          Rpush.logger.warn("Couldn't find Rpush::Client::Redis::Notification with id=#{id}")
          nil
        end

        def create_gcm_like_notification(notification, attrs, data, registration_ids, deliver_after, app) # rubocop:disable Metrics/ParameterLists
          notification.assign_attributes(attrs)
          notification.data = data
          notification.registration_ids = registration_ids
          notification.deliver_after = deliver_after
          notification.app = app
          notification.save!
          notification
        end

        def retryable_notification_ids
          retryable_ns = Rpush::Client::Redis::Notification.absolute_retryable_namespace

          Modis.with_connection do |redis|
            retryable_results = redis.multi do |transaction|
              now = Time.now.to_i
              transaction.zrangebyscore(retryable_ns, 0, now)
              transaction.zremrangebyscore(retryable_ns, 0, now)
            end

            retryable_results.first
          end
        end

        def pending_notification_ids(limit)
          limit = [0, limit - 1].max # 'zrange key 0 1' will return 2 values, not 1.
          pending_ns = Rpush::Client::Redis::Notification.absolute_pending_namespace

          Modis.with_connection do |redis|
            pending_results = redis.multi do |transaction|
              transaction.zrange(pending_ns, 0, limit)
              transaction.zremrangebyrank(pending_ns, 0, limit)
            end

            pending_results.first
          end
        end
      end
    end
  end
end

Rpush::Daemon::Store::Interface.check(Rpush::Daemon::Store::Redis)
