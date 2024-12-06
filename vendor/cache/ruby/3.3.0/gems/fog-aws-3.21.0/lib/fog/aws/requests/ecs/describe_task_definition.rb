module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/describe_task_definition'

        # Describes a task definition
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DescribeTaskDefinition.html
        # ==== Parameters
        # * taskDefinition <~String> - The family for the latest revision, family and revision (family:revision) for a specific revision in the family, or full Amazon Resource Name (ARN) of the task definition that you want to describe.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'taskDefinition' <~Hash> - full task definition description
        def describe_task_definition(params={})
          request({
            'Action'  => 'DescribeTaskDefinition',
            :parser   => Fog::Parsers::AWS::ECS::DescribeTaskDefinition.new
          }.merge(params))
        end
      end

      class Mock
        def describe_task_definition(params={})
          response = Excon::Response.new
          response.status = 200

          taskdef_error = "ClientException => Task Definition can not be blank."
          raise Fog::AWS::ECS::Error, taskdef_error unless params['taskDefinition']

          task_def_name = params['taskDefinition']

          case task_def_name
          when /^arn:aws:ecs:.+:\d{1,12}:task-definition\/(.+:.+)$/
            result = self.data[:task_definitions].select { |t| t['taskDefinitionArn'].eql?(task_def_name) }
          when /^(.+:.+)$/
            result = self.data[:task_definitions].select { |t| t['taskDefinitionArn'].match(/task-definition\/#{task_def_name}/) }
          else
            result = self.data[:task_definitions].select { |t| t['family'].eql?(task_def_name) }
            if !result.empty?
              result = [] << (result.max_by { |t| t['revision'] })
            end
          end

          if result.empty?
            raise Fog::AWS::ECS::Error, 'ClientException => Unable to describe task definition.'
          end

          task_definition = result.first

          response.body = {
            'DescribeTaskDefinitionResult' => {
              'taskDefinition' => task_definition
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
