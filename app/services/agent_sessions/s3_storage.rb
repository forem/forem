module AgentSessions
  class S3Storage
    BUCKET_PREFIX = "agent_sessions".freeze
    DEFAULT_TTL = 900 # 15 minutes
    CONTENT_TYPE = "application/x-jsonlines".freeze
    # Raw uploads share the size cap applied to a session's curated data. The
    # byte count is signed into the presigned PUT, so S3 rejects any body whose
    # Content-Length differs from what the client declared at presign time.
    MAX_UPLOAD_SIZE = AgentSession::MAX_CURATED_DATA_SIZE
    CONTENT_LENGTH_ERROR = "content_length is required and must be an integer number of bytes " \
                           "between 1 and #{MAX_UPLOAD_SIZE}".freeze

    class << self
      ALLOWED_EXTENSIONS = %w[.jsonl .json].freeze
      S3_KEY_REGEX = %r{\A#{BUCKET_PREFIX}/(?<user_id>\d+)/[0-9a-fA-F-]{36}(?<extension>\.(?:jsonl|json))\z}

      def generate_key(user_id, filename = nil)
        ext = if filename
                candidate = File.extname(filename).downcase
                ALLOWED_EXTENSIONS.include?(candidate) ? candidate : ".jsonl"
              else
                ".jsonl"
              end
        "#{BUCKET_PREFIX}/#{user_id}/#{SecureRandom.uuid}#{ext}"
      end

      def valid_key_for_user?(s3_key, user_id)
        return false if s3_key.blank? || user_id.blank?

        match = s3_key.match(S3_KEY_REGEX)
        match.present? && match[:user_id] == user_id.to_s
      end

      # @param value [Integer, String, nil] the client-declared upload size in bytes
      # @return [Integer, nil] the size, or nil when missing, malformed or over MAX_UPLOAD_SIZE
      def permitted_content_length(value)
        content_length = value.is_a?(Integer) ? value : Integer(value.to_s, 10, exception: false)
        content_length if content_length&.between?(1, MAX_UPLOAD_SIZE)
      end

      # Headers the client must send with the PUT; each one is part of the signature.
      def upload_headers(content_length, content_type: CONTENT_TYPE)
        {
          "Content-Type" => content_type,
          "Content-Length" => content_length.to_s,
          "x-amz-acl" => "private"
        }
      end

      def presigned_put_url(s3_key, content_length:, content_type: CONTENT_TYPE, expires_in: DEFAULT_TTL)
        raise ArgumentError, CONTENT_LENGTH_ERROR unless permitted_content_length(content_length)

        storage.put_object_url(
          bucket,
          s3_key,
          Time.now.to_i + expires_in,
          upload_headers(content_length, content_type: content_type),
        )
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
        ApplicationConfig["AWS_ID"].present? && bucket.present?
      end

      private

      def storage
        @storage ||= Fog::Storage.new(credentials)
      end

      def credentials
        {
          provider: "AWS",
          aws_access_key_id: ApplicationConfig["AWS_ID"],
          aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
          region: ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
        }
      end

      def bucket
        ApplicationConfig["AWS_AGENT_SESSIONS_BUCKET_NAME"].presence || ApplicationConfig["AWS_BUCKET_NAME"]
      end
    end
  end
end
