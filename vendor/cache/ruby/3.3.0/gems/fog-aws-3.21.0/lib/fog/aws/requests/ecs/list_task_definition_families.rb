module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/list_task_definition_families'

        # Returns a list of task definition families that are registered to your account.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ListTaskDefinitionFamilies.html
        # ==== Parameters
        # * familyPrefix <~String> - familyPrefix is a string that is used to filter the results of ListTaskDefinitionFamilies.
        # * maxResults <~Integer> - maximum number of task definition family results returned by ListTaskDefinitionFamilies in paginated output.
        # * nextToken <~String> - nextToken value returned from a previous paginated ListTaskDefinitionFamilies request where maxResults was used.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Families' <~Array> - list of task definition family names that match the ListTaskDefinitionFamilies request.
        #     * 'NextToken' <~String> - nextToken value to include in a future ListTaskDefinitionFamilies request.
        def list_task_definition_families(params={})
          request({
            'Action'  => 'ListTaskDefinitionFamilies',
            :parser   => Fog::Parsers::AWS::ECS::ListTaskDefinitionFamilies.new
          }.merge(params))
        end
      end

      class Mock
        def list_task_definition_families(params={})
          response = Excon::Response.new
          response.status = 200

          family_prefix = params['familyPrefix']

          if family_prefix
            result = self.data[:task_definitions].select do |t|
              t['family'].match(/^#{family_prefix}/)
            end
          else
            result = self.data[:task_definitions].dup
          end
          result.map! { |t| t['family'] }
          result.uniq!

          response.body = {
            'ListTaskDefinitionFamiliesResult' => {
              'families' => result
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
