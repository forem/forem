module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/remove_permission'

        def remove_permission(options = {})
          request({
            'Action'  => 'RemovePermission',
            :parser   => Fog::Parsers::AWS::SNS::RemovePermission.new
          }.merge!(options))
        end
      end

      class Mock
        def remove_permission(options = {})
          topic_arn = options['TopicArn']
          label     = options['Label']

          self.data[:permissions][topic_arn].delete(label)

          response = Excon::Response.new
          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
