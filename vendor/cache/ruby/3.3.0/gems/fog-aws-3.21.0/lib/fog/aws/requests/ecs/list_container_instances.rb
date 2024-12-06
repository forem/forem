module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/list_container_instances'

        # Returns a list of container instances in a specified cluster.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ListContainerInstances.html
        # ==== Parameters
        # * cluster <~String> - short name or full Amazon Resource Name (ARN) of the cluster that hosts the container instances you want to list.
        # * maxResults <~Integer> - maximum number of container instance results returned by ListContainerInstances in paginated output.
        # * nextToken <~String> - nextToken value returned from a previous paginated ListContainerInstances request where maxResults was used.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ContainerInstanceArns' <~Array> - list of container instance full ARN entries for each container instance associated with the specified cluster.
        #     * 'NextToken' <~String> - nextToken value to include in a future ListContainerInstances request.
        def list_container_instances(params={})
          request({
            'Action'  => 'ListContainerInstances',
            :parser   => Fog::Parsers::AWS::ECS::ListContainerInstances.new
          }.merge(params))
        end
      end

      class Mock
        def list_container_instances(params={})
          response = Excon::Response.new
          response.status = 200

          instance_arns = self.data[:container_instances].map { |i| i['containerInstanceArn'] }

          response.body = {
            'ListContainerInstancesResult' => {
              'containerInstanceArns' => instance_arns
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
