module Fog
  module AWS
    class ECS
      class Real
        require 'fog/aws/parsers/ecs/create_cluster'

        # Creates a new Amazon ECS cluster
        # http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CreateCluster.html
        # ==== Parameters
        # * clusterName <~String> - The name of your cluster.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Cluster' <~Hash> - The full description of your new cluster
        def create_cluster(params={})
          request({
            'Action' => 'CreateCluster',
            :parser  => Fog::Parsers::AWS::ECS::CreateCluster.new
          }.merge(params))
        end
      end

      class Mock
        def create_cluster(params={})
          response = Excon::Response.new
          response.status = 200

          params.has_key?('clusterName') || params['clusterName'] = 'default'

          owner_id = Fog::AWS::Mock.owner_id
          cluster_name = params['clusterName']
          cluster_path = "cluster/#{cluster_name}"
          cluster_arn = Fog::AWS::Mock.arn('ecs', owner_id, cluster_path, region)
          cluster = {}

          search_cluster_result = self.data[:clusters].select { |c| c['clusterName'].eql?(cluster_name) }
          if search_cluster_result.empty?
            cluster = {
              'clusterName'                       => cluster_name,
              'clusterArn'                        => cluster_arn,
              'status'                            => 'ACTIVE',
              'registeredContainerInstancesCount' => 0,
              'runningTasksCount'                 => 0,
              'pendingTasksCount'                 => 0
            }
            self.data[:clusters] << cluster
          else
            cluster = search_cluster_result.first
          end

          response.body = {
            'CreateClusterResult' => {
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
