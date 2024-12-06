require 'fog/aws/models/rds/cluster'

module Fog
  module AWS
    class RDS
      class Clusters < Fog::Collection
        model Fog::AWS::RDS::Cluster

        def all
          data = service.describe_db_clusters.body['DescribeDBClustersResult']['DBClusters']
          load(data)
        end

        def get(identity)
          data = service.describe_db_clusters(identity).body['DescribeDBClustersResult']['DBClusters'].first
          new(data)
        rescue Fog::AWS::RDS::NotFound
          nil
        end
      end
    end
  end
end
