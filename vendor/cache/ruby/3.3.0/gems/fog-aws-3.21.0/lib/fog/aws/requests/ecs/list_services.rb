module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/list_services'

        # Lists the services that are running in a specified cluster.
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ListServices.html
        # ==== Parameters
        # * cluster <~String> - The short name or full Amazon Resource Name (ARN) of the cluster that hosts the services you want to list.
        # * maxResults <~Integer> - The maximum number of container instance results returned by ListServices in paginated output.
        # * nextToken <~String> - The nextToken value returned from a previous paginated ListServices request where maxResults was used.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ServiceArns' <~Array> - list of full Amazon Resource Name (ARN) entries for each service associated with the specified cluster.
        #     * 'NextToken' <~String> - nextToken value to include in a future ListServices request.
        def list_services(params={})
          request({
            'Action'  => 'ListServices',
            :parser   => Fog::Parsers::AWS::ECS::ListServices.new
          }.merge(params))
        end
      end

      class Mock
        def list_services(params={})
          response = Excon::Response.new
          response.status = 200

          owner_id = Fog::AWS::Mock.owner_id

          cluster = params.delete('cluster') || 'default'
          if !cluster.match(/^arn:aws:ecs:.+:.+:cluster\/(.+)$/)
            cluster_path = "cluster/#{cluster}"
            cluster_arn = Fog::AWS::Mock.arn('ecs', owner_id, cluster_path, region)
          else
            cluster_arn = cluster
          end

          result = self.data[:services].select do |s|
            s['clusterArn'].eql?(cluster_arn)
          end
          service_arns = result.map { |s| s['serviceArn'] }

          response.body = {
            'ListServicesResult' => {
              'serviceArns' => service_arns
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
