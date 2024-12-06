module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/describe_container_instances'

        # Describes Amazon EC2 Container Service container instances.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DescribeContainerInstances.html
        # ==== Parameters
        # * cluster <~String> - short name or full ARN of the cluster that hosts the container instances you want to describe.
        # * containerInstances <~Array> - list of container instance UUIDs or full Amazon Resource Name (ARN) entries.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'containerInstances' <~Array> - list of container instances.
        #     * 'failures' <~Array> - list of failures (if any)
        def describe_container_instances(params={})
          if instances = params.delete('containerInstances')
            params.merge!(Fog::AWS.indexed_param('containerInstances.member', [*instances]))
          end

          request({
            'Action'  => 'DescribeContainerInstances',
            :parser   => Fog::Parsers::AWS::ECS::DescribeContainerInstances.new
          }.merge(params))
        end
      end

      class Mock
        def describe_container_instances(params={})
          response = Excon::Response.new
          response.status = 200

          cluster = params.delete('cluster') || 'default'

          instances_id = params.delete('containerInstances')
          msg = 'ClientException => Container instance cannot be empty.'
          raise Fog::AWS::ECS::Error, msg unless instances_id

          result = []
          [*instances_id].each do |inst|
            if match = inst.match(/^arn:aws:ecs:.+:\d{1,12}:container-instance\/(.+)$/)
              result = self.data[:container_instances].select { |i| i['containerInstanceArn'].eql?(inst) }
            else
              result = self.data[:container_instances].select { |i| i['containerInstanceArn'].match(/#{inst}$/) }
            end
          end

          instances = result
          response.body = {
            'DescribeContainerInstancesResult' => {
              'containerInstances' => instances,
              'failures'           => []
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
