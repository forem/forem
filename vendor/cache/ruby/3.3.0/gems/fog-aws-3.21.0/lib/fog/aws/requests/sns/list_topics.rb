module Fog
  module AWS
    class SNS
      class Real
        require 'fog/aws/parsers/sns/list_topics'

        # List topics
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'NextToken'<~String> - Token returned from previous request, used for pagination
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/sns/latest/api/API_ListTopics.html
        #

        def list_topics(options = {})
          request({
            'Action'  => 'ListTopics',
            :parser   => Fog::Parsers::AWS::SNS::ListTopics.new
          }.merge!(options))
        end
      end

      class Mock
        def list_topics(options={})
          response = Excon::Response.new

          response.body = {'Topics' => self.data[:topics].keys, 'RequestId' => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
