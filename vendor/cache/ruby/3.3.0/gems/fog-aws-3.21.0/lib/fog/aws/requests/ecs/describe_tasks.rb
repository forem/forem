module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/describe_tasks'

        # Describes a specified task or tasks.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DescribeTasks.html
        # ==== Parameters
        # * cluster <~String> - short name or full Amazon Resource Name (ARN) of the cluster that hosts the task you want to describe
        # * tasks <~Array> - space-separated list of task UUIDs or full Amazon Resource Name (ARN) entries
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'tasks' <~Array> - The list of tasks
        #     * 'failures' <~Array> - The list of failures (if any)
        def describe_tasks(params={})
          if tasks = params.delete('tasks')
            params.merge!(Fog::AWS.indexed_param('tasks.member', [*tasks]))
          end

          request({
            'Action'  => 'DescribeTasks',
            :parser   => Fog::Parsers::AWS::ECS::DescribeTasks.new
          }.merge(params))
        end
      end

      class Mock
        def describe_tasks(params={})
          response = Excon::Response.new
          response.status = 200

          unless tasks = params.delete('tasks')
            msg = 'InvalidParameterException => Tasks cannot be empty.'
            raise Fog::AWS::ECS::Error, msg
          end

          cluster = params.delete('cluster') || 'default'

          result = []
          [*tasks].each do |tid|
            if match = tid.match(/^arn:aws:ecs:.+:\d{1,12}:task\/(.+)$/)
              result = self.data[:tasks].select { |t| t['taskArn'].eql?(tid) }
            else
              result = self.data[:tasks].select { |t| t['taskArn'].match(/#{tid}$/) }
            end
          end

          tasks = result
          response.body = {
            'DescribeTasksResult' => {
              'failures' => [],
              'tasks' => tasks
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
