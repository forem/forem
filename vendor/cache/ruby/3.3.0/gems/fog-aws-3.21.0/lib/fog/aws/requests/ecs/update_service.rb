module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/update_service'

        # Modify the desired count or task definition used in a service.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_UpdateService.html
        # ==== Parameters
        # * cluster <~String> - short name or full Amazon Resource Name (ARN) of the cluster that your service is running on.
        # * desiredCount <~Integer> - number of instantiations of the task that you would like to place and keep running in your service.
        # * service <~String> - name of the service that you want to update.
        # * taskDefinition <~String> - family and revision (family:revision) or full Amazon Resource Name (ARN) of the task definition that you want to run in your service.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Service'<~Hash> - The full description of the updated cluster
        def update_service(params={})
          request({
            'Action'  => 'UpdateService',
            :parser   => Fog::Parsers::AWS::ECS::UpdateService.new
          }.merge(params))
        end
      end

      class Mock
        def update_service(params={})
          response = Excon::Response.new
          response.status = 200

          service_id = params.delete('service')
          msg = 'ClientException => Service cannot be empty.'
          raise Fog::AWS::ECS::Error, msg unless service_id

          owner_id = Fog::AWS::Mock.owner_id

          cluster = params.delete('cluster') || 'default'
          if !cluster.match(/^arn:aws:ecs:.+:.+:cluster\/(.+)$/)
            cluster_path = "cluster/#{cluster}"
            cluster_arn = Fog::AWS::Mock.arn('ecs', owner_id, cluster_path, region)
          else
            cluster_arn = cluster
          end

          if match = service_id.match(/^arn:aws:ecs:.+:\d{1,12}:service\/(.+)$/)
            i = self.data[:services].index do |s|
              s['clusterArn'].eql?(cluster_arn) && s['serviceArn'].eql?(service_id)
            end
          else
            i = self.data[:services].index do |s|
              s['clusterArn'].eql?(cluster_arn) && s['serviceName'].eql?(service_id)
            end
          end

          msg = "ServiceNotFoundException => Service not found."
          raise Fog::AWS::ECS::Error, msg unless i

          service = self.data[:services][i]

          if desired_count = params.delete('desiredCount')
            # ignore
          end

          if task_definition = params.delete('taskDefinition')
            service['taskDefinition'] = task_definition
          end

          response.body = {
            'UpdateServiceResult' => {
              'service' => service
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
