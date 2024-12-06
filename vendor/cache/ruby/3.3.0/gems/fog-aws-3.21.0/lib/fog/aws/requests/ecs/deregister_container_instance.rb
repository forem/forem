module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/deregister_container_instance'

        # Deregisters an Amazon ECS container instance from the specified cluster.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeregisterContainerInstance.html
        # ==== Parameters
        # * cluster <~String> - short name or full ARN of the cluster that hosts the container instance you want to deregister.
        # * containerInstance <~String> - container instance UUID or full Amazon Resource Name (ARN) of the container instance you want to deregister.
        # * force <~Boolean> - Force the deregistration of the container instance.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ContainerInstance' <~Hash> - full description of the deregistered container instance
        def deregister_container_instance(params={})
          request({
            'Action'  => 'DeregisterContainerInstance',
            :parser   => Fog::Parsers::AWS::ECS::DeregisterContainerInstance.new
          }.merge(params))
        end
      end

      class Mock
        def deregister_container_instance(params={})
          response = Excon::Response.new
          response.status = 200

          instance_id = params.delete('containerInstance')
          instance_error = "ClientException => Container instance can not be blank."
          raise Fog::AWS::ECS::Error, instance_error unless instance_id

          if match = instance_id.match(/^arn:aws:ecs:.+:\d{1,12}:container-instance\/(.+)$/)
            i = self.data[:container_instances].index do |inst|
              inst['containerInstanceArn'].eql?(instance_id)
            end
          else
            i = self.data[:container_instances].index do |inst|
              inst['containerInstanceArn'].match(/#{instance_id}$/)
            end
          end

          msg = "ClientException => Referenced container instance #{instance_id} not found."
          raise Fog::AWS::ECS::Error, msg unless i

          instance = self.data[:container_instances][i]
          self.data[:container_instances].delete_at(i)

          response.body = {
            'DeregisterContainerInstanceResult' => {
              'containerInstance' => instance
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
