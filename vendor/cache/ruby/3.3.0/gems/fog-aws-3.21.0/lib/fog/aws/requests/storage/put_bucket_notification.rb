module Fog
  module AWS
    class Storage
      class Real
        # Change notification configuration for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to set notification configuration for
        # * notications [Hash]:
        #   * Topics [Array] SNS topic configurations for the notification
        #     * ID [String] Unique identifier for the configuration
        #     * Topic [String] Amazon SNS topic ARN to which Amazon S3 will publish a message when it detects events of specified type
        #     * Event [String] Bucket event for which to send notifications
        #   * Queues [Array] SQS queue configurations for the notification
        #     * ID [String] Unique identifier for the configuration
        #     * Queue [String] Amazon SQS queue ARN to which Amazon S3 will publish a message when it detects events of specified type
        #     * Event [String] Bucket event for which to send notifications
        #   * CloudFunctions [Array] AWS Lambda notification configurations
        #     * ID [String] Unique identifier for the configuration
        #     * CloudFunction [String] Lambda cloud function ARN that Amazon S3 can invoke when it detects events of the specified type
        #     * InvocationRole [String] IAM role ARN that Amazon S3 can assume to invoke the specified cloud function on your behalf
        #     * Event [String] Bucket event for which to send notifications
        #
        # @see http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
        #
        def put_bucket_notification(bucket_name, notification)
          builder = Nokogiri::XML::Builder.new do
            NotificationConfiguration do
              notification.fetch('Topics', []).each do |topic|
                TopicConfiguration do
                  Id    topic['Id']
                  Topic topic['Topic']
                  Event topic['Event']
                end
              end
              notification.fetch('Queues', []).each do |queue|
                QueueConfiguration do
                  Id    queue['Id']
                  Queue queue['Queue']
                  Event queue['Event']
                end
              end
              notification.fetch('CloudFunctions', []).each do |func|
                CloudFunctionConfiguration do
                  Id             func['Id']
                  CloudFunction  func['CloudFunction']
                  InvocationRole func['InvocationRole']
                  Event          func['Event']
                end
              end
            end
          end
          body = builder.to_xml
          body.gsub!(/<([^<>]+)\/>/, '<\1></\1>')
          request({
            :body     => body,
            :expects  => 200,
            :headers  => {'Content-MD5' => Base64.encode64(OpenSSL::Digest::MD5.digest(body)).chomp!,
              'Content-Type' => 'application/xml'},
            :bucket_name => bucket_name,
            :method   => 'PUT',
            :query    => {'notification' => nil}
          })
        end
      end

      class Mock
        def put_bucket_notification(bucket_name, notification)
          response = Excon::Response.new

          if self.data[:buckets][bucket_name]
            self.data[:bucket_notifications][bucket_name] = notification
            response.status = 204
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 204}, response))
          end

          response
        end
      end
    end
  end
end
