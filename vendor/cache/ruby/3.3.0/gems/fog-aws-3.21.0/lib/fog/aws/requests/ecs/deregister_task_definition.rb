module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/deregister_task_definition'

        # Deregisters the specified task definition.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeregisterTaskDefinition.html
        # ==== Parameters
        # * taskDefinition <~String> - The family and revision (family:revision) or full Amazon Resource Name (ARN) of the task definition that you want to deregister.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'TaskDefinition' <~Hash> - full description of the deregistered task
        def deregister_task_definition(params={})
          request({
            'Action'  => 'DeregisterTaskDefinition',
            :parser   => Fog::Parsers::AWS::ECS::DeregisterTaskDefinition.new
          }.merge(params))
        end
      end

      class Mock
        def deregister_task_definition(params={})
          response = Excon::Response.new
          response.status = 200

          taskdef_error = "ClientException => Task Definition can not be blank."
          raise Fog::AWS::ECS::Error, taskdef_error unless params['taskDefinition']

          task_def_name = params['taskDefinition']

          case task_def_name
          when /^arn:aws:ecs:.+:\d{1,12}:task-definition\/(.+:.+)$/
            i = self.data[:task_definitions].index { |t| t['taskDefinitionArn'].eql?(task_def_name) }
          when /^(.+:.+)$/
            i = self.data[:task_definitions].index { |t| t['taskDefinitionArn'].match(/task-definition\/#{task_def_name}$/) }
          else
            raise Fog::AWS::ECS::Error, 'Invalid task definition'
          end

          raise Fog::AWS::ECS::NotFound, 'Task definition not found.' unless i
          task_definition = self.data[:task_definitions].delete_at(i)

          response.body = {
            'DeregisterTaskDefinitionResult' => {
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
