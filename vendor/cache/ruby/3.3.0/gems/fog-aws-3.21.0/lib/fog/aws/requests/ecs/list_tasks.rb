module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/list_tasks'

        # Returns a list of tasks for a specified cluster.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ListTasks.html
        # ==== Parameters
        # * cluster <~String> - short name or full Amazon Resource Name (ARN) of the cluster that hosts the tasks you want to list.
        # * containerInstance <~String> - container instance UUID or full Amazon Resource Name (ARN) of the container instance that you want to filter the ListTasks results with.
        # * family <~String> - name of the family that you want to filter the ListTasks results with.
        # * maxResults <~Integer> - maximum number of task results returned by ListTasks in paginated output.
        # * nextToken <~String> - nextToken value returned from a previous paginated ListTasks request where maxResults was used.
        # * serviceName <~String> - name of the service that you want to filter the ListTasks results with.
        # * startedBy <~String> - startedBy value that you want to filter the task results with.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'TaskArns' <~Array> - list of task Amazon Resource Name (ARN) entries for the ListTasks request.
        #     * 'NextToken' <~String> - nextToken value to include in a future ListTasks request.
        def list_tasks(params={})
          request({
            'Action'  => 'ListTasks',
            :parser   => Fog::Parsers::AWS::ECS::ListTasks.new
          }.merge(params))
        end
      end

      class Mock
        def list_tasks(params={})
          response = Excon::Response.new
          response.status = 200

          task_arns = self.data[:tasks].map { |t| t['taskArn'] }

          response.body = {
            'ListTasksResult' => {
              'taskArns' => task_arns
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
