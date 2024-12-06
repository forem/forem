module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/list_task_definitions'

        # Returns a list of task definitions that are registered to your account
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ListTaskDefinitions.html
        # ==== Parameters
        # * familyPrefix <~String> - The full family name that you want to filter the ListTaskDefinitions results with.
        # * maxResults <~Integer> - The maximum number of task definition results returned by ListTaskDefinitions in paginated output.
        # * nextToken <~String> - The nextToken value returned from a previous paginated ListTaskDefinitions request.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'TaskDefinitionArns' <~Array> - list of task definition Amazon Resource Name (ARN) entries for the ListTaskDefintions request.
        #     * 'NextToken' <~String> - nextToken value to include in a future ListTaskDefinitions request
        def list_task_definitions(params={})
          request({
            'Action'  => 'ListTaskDefinitions',
            :parser   => Fog::Parsers::AWS::ECS::ListTaskDefinitions.new
          }.merge(params))
        end
      end

      class Mock
        def list_task_definitions(params={})
          if %w(
            familyPrefix
            maxResults
            nextToken
            ).any? { |k| params.has_key?(k) }
            Fog::Logger.warning("list_task_definitions filters are not yet mocked [light_black](#{caller.first})[/]")
            Fog::Mock.not_implemented
          end

          response = Excon::Response.new
          response.status = 200

          taskdef_arns = self.data[:task_definitions].map { |c| c['taskDefinitionArn'] }

          response.body = {
            'ListTaskDefinitionsResult' => {
              'taskDefinitionArns' => taskdef_arns
            },
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            }
          }
          response
        end
      end
    end
  end
end
