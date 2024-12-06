module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/get_bucket_notification'

        # Get bucket notification configuration
        #
        # @param bucket_name [String] name of bucket to get notification configuration for
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * Topics [Array] SNS topic configurations for the notification
        #       * ID [String] Unique identifier for the configuration
        #       * Topic [String] Amazon SNS topic ARN to which Amazon S3 will publish a message when it detects events of specified type
        #       * Event [String] Bucket event for which to send notifications
        #     * Queues [Array] SQS queue configurations for the notification
        #       * ID [String] Unique identifier for the configuration
        #       * Queue [String] Amazon SQS queue ARN to which Amazon S3 will publish a message when it detects events of specified type
        #       * Event [String] Bucket event for which to send notifications
        #     * CloudFunctions [Array] AWS Lambda notification configurations
        #       * ID [String] Unique identifier for the configuration
        #       * CloudFunction [String] Lambda cloud function ARN that Amazon S3 can invoke when it detects events of the specified type
        #       * InvocationRole [String] IAM role ARN that Amazon S3 can assume to invoke the specified cloud function on your behalf
        #       * Event [String] Bucket event for which to send notifications
        #
        # @see http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGETnotification.html
        def get_bucket_notification(bucket_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects    => 200,
            :headers    => {},
            :bucket_name => bucket_name,
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::Parsers::AWS::Storage::GetBucketNotification.new,
            :query      => {'notification' => nil}
          })
        end
      end

      class Mock
        def get_bucket_notification(bucket_name)
          response = Excon::Response.new

          if self.data[:buckets][bucket_name] && self.data[:bucket_notifications][bucket_name]
            response.status = 200
            response.body = self.data[:bucket_notifications][bucket_name]
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end
      end
    end
  end
end
