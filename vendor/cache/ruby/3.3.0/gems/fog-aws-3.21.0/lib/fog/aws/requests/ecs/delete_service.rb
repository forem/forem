module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/delete_service'

        # Deletes a specified service within a cluster.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeleteService.html
        # ==== Parameters
        # * cluster <~String> - name of the cluster that hosts the service you want to delete.
        # * service <~String> - name of the service you want to delete.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Service'<~Hash> - The full description of the deleted service
        def delete_service(params={})
          request({
            'Action'  => 'DeleteService',
            :parser   => Fog::Parsers::AWS::ECS::DeleteService.new
          }.merge(params))
        end
      end

      class Mock
        def delete_service(params={})
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
          self.data[:services].delete_at(i)

          response.body = {
            'DeleteServiceResult' => {
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
