module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/delete_cluster'

        # Deletes the specified cluster
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeleteCluster.html
        # ==== Parameters
        # * cluster <~String> - The short name or full Amazon Resource Name (ARN) of the cluster that you want to delete
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Cluster'<~Hash> - The full description of the deleted cluster
        def delete_cluster(params={})
          request({
            'Action'  => 'DeleteCluster',
            :parser   => Fog::Parsers::AWS::ECS::DeleteCluster.new
          }.merge(params))
        end
      end

      class Mock
        def delete_cluster(params={})
          response = Excon::Response.new
          response.status = 200

          cluster_id = params.delete('cluster')

          if !cluster_id
            message = 'ClientException => Cluster can not be blank.'
            raise Fog::AWS::ECS::Error, message
          end

          if match = cluster_id.match(/^arn:aws:ecs:.+:\d{1,12}:cluster\/(.+)$/)
            i = self.data[:clusters].index { |c| c['clusterArn'].eql?(cluster_id) }
          else
            i = self.data[:clusters].index { |c| c['clusterName'].eql?(cluster_id) }
          end

          if i
            cluster = self.data[:clusters].delete_at(i)
          else
            raise Fog::AWS::ECS::NotFound, 'Cluster not found.'
          end

          cluster['status'] = 'INACTIVE'
          response.body = {
            'DeleteClusterResult' => {
              'cluster' => cluster
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
