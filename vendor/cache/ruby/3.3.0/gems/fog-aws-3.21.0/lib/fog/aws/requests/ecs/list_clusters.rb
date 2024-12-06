module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/list_clusters'

        # Returns a list of existing clusters
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ListClusters.html
        # ==== Parameters
        # * maxResults <~Integer> - The maximum number of cluster results returned by ListClusters in paginated output.
        # * nextToken <~String> - The nextToken value returned from a previous paginated ListClusters request where maxResults was used.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ClusterArns' <~Array> - list of full Amazon Resource Name (ARN) entries for each cluster associated with your account.
        #     * 'NextToken' <~String> - nextToken value to include in a future ListClusters request.
        def list_clusters(params={})
          request({
            'Action'  => 'ListClusters',
            :parser   => Fog::Parsers::AWS::ECS::ListClusters.new
          }.merge(params))
        end
      end

      class Mock
        def list_clusters(params={})
          response = Excon::Response.new
          response.status = 200

          cluster_arns = self.data[:clusters].map { |c| c['clusterArn'] }

          response.body = {
            'ListClustersResult' => {
              'clusterArns' => cluster_arns
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
