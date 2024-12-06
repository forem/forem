module Rpush
  module Client
    module Redis
      class Notification
        include Rpush::MultiJsonHelper
        include Modis::Model
        include Rpush::Client::ActiveModel::Notification

        after_create :register_notification

        self.namespace = 'notifications'

        def self.absolute_pending_namespace
          "#{absolute_namespace}:pending"
        end

        def self.absolute_retryable_namespace
          "#{absolute_namespace}:retryable"
        end

        attribute :badge, :integer
        attribute :device_token, :string
        attribute :sound, [:string, :hash], strict: false, default: 'default'
        attribute :alert, [:string, :hash], strict: false
        attribute :data, :hash
        attribute :expiry, :integer, default: 1.day.to_i
        attribute :delivered, :boolean
        attribute :delivered_at, :timestamp
        attribute :failed, :boolean
        attribute :failed_at, :timestamp
        attribute :fail_after, :timestamp
        attribute :retries, :integer, default: 0
        attribute :error_code, :integer
        attribute :error_description, :string
        attribute :deliver_after, :timestamp
        attribute :alert_is_json, :boolean
        attribute :sound_is_json, :boolean
        attribute :app_id, :integer
        attribute :collapse_key, :string
        attribute :delay_while_idle, :boolean
        attribute :registration_ids, :array
        attribute :uri, :string
        attribute :priority, :integer
        attribute :url_args, :array
        attribute :category, :string
        attribute :content_available, :boolean, default: false
        attribute :dry_run, :boolean, default: false
        attribute :mutable_content, :boolean, default: false
        attribute :notification, :hash
        attribute :thread_id, :string

        def app
          return nil unless app_id
          @app ||= Rpush::Client::Redis::App.find(app_id)
        end

        def app=(app)
          @app = app
          if app
            self.app_id = app.id
          else
            self.app_id = nil
          end
        end

        private

        def register_notification
          Modis.with_connection do |redis|
            redis.zadd(self.class.absolute_pending_namespace, id, id)
          end
        end
      end
    end
  end
end
