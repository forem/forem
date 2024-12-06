module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/register_task_definition'

        # Registers a new task definition from the supplied family and containerDefinitions.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_RegisterTaskDefinition.html
        # ==== Parameters
        # * containerDefinitions <~Array> - list of container definitions in JSON format that describe the different containers that make up your task.
        # * family <~String> - family for a task definition, which allows you to track multiple versions of the same task definition.
        # * volumes <~String> - list of volume definitions in JSON format that containers in your task may use.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'TaskDefinition' <~Array> - full task definition description registered
        def register_task_definition(params={})
          serialized_params = {}
          params.each_pair do |k,v|
            serialized_params.merge!(Fog::AWS.serialize_keys(k, v))
          end
          request({
            'Action'  => 'RegisterTaskDefinition',
            :parser   => Fog::Parsers::AWS::ECS::RegisterTaskDefinition.new
          }.merge(serialized_params))
        end
      end

      class Mock
        def register_task_definition(params={})
          response = Excon::Response.new
          response.status = 200

          family_error = 'ClientException => Family can not be blank.'
          container_error = 'ClientException => Container list cannot be empty.'
          raise Fog::AWS::ECS::Error, family_error    unless params['family']
          raise Fog::AWS::ECS::Error, container_error unless params['containerDefinitions']

          owner_id = Fog::AWS::Mock.owner_id
          taskdef_name = params['family']
          taskdef_rev = (1..9).to_a.shuffle.first
          taskdef_path = "task-definition/#{taskdef_name}:#{taskdef_rev}"
          taskdef_arn = Fog::AWS::Mock.arn('ecs', owner_id, taskdef_path, region)

          task_definition = {
            'revision'             => taskdef_rev,
            'taskDefinitionArn'    => taskdef_arn,
            'family'               => params['family'],
            'containerDefinitions' => params['containerDefinitions']
          }
          task_definition['volumes'] = params['volumes'] if params['volumes']

          self.data[:task_definitions] << task_definition

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'RegisterTaskDefinitionResult' => {
              'taskDefinition' => task_definition
            }
          }
          response
        end
      end
    end
  end
end
