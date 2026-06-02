module AgentSessions
  class S3Storage
    BUCKET_PREFIX = "agent_sessions".freeze
    DEFAULT_TTL = 900 # 15 minutes
    CONTENT_TYPE = "application/x-jsonlines".freeze

    class << self
      ALLOWED_EXTENSIONS = %w[.jsonl .json].freeze

      def generate_key(user_id, filename = nil)
        ext = if filename
                candidate = File.extname(filename).downcase
                ALLOWED_EXTENSIONS.include?(candidate) ? candidate : ".jsonl"
              else
                ".jsonl"
              end
        "#{BUCKET_PREFIX}/#{user_id}/#{SecureRandom.uuid}#{ext}"
      end

      def presigned_put_url(s3_key, content_type: CONTENT_TYPE, expires_in: DEFAULT_TTL)
        storage.put_object_url(bucket, s3_key, Time.now.to_i + expires_in, "Content-Type" => content_type)
      end

      def presigned_get_url(s3_key, expires_in: DEFAULT_TTL)
        storage.get_object_url(bucket, s3_key, Time.now.to_i + expires_in)
      end

      def delete(s3_key)
        storage.delete_object(bucket, s3_key)
      rescue Excon::Error => e
        Rails.logger.warn("AgentSessions::S3Storage#delete failed for #{s3_key}: #{e.message}")
      end

      def enabled?
        ApplicationConfig["AWS_ID"].present? && ApplicationConfig["AWS_BUCKET_NAME"].present?
      end

      private

      def storage
        @storage ||= Fog::Storage.new(credentials)
      end

      def credentials
        credentials = {
          provider: "AWS",
          aws_access_key_id: ApplicationConfig["AWS_ID"],
          aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
          region: ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"],
        }

        endpoint = ApplicationConfig["AWS_ENDPOINT_URL"]
        credentials[:endpoint] = endpoint if endpoint.present?

        force_path_style = ApplicationConfig["AWS_FORCE_PATH_STYLE"]
        if force_path_style.present?
          credentials[:path_style] = ActiveModel::Type::Boolean.new.cast(force_path_style)
        end

        credentials
      end

      def bucket
        ApplicationConfig["AWS_BUCKET_NAME"]
      end
    end
  end
end
