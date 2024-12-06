module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/add_permission'

        def add_permission(options = {})
          request({
            'Action'  => 'AddPermission',
            :parser   => Fog::Parsers::AWS::SNS::AddPermission.new
          }.merge!(options))
        end
      end

      class Mock
        def add_permission(options = {})
          topic_arn = options.delete('TopicArn')
          label     = options.delete('Label')
          actions   = Hash[options.select { |k,v| k.match(/^ActionName/) }].values
          members   = Hash[options.select { |k,v| k.match(/^AWSAccountId/) }].values

          self.data[:permissions][topic_arn][label] = {
            :members => members,
            :actions => actions,
          }

          response = Excon::Response.new
          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
