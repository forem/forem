require 'fog/aws/models/rds/snapshot'

module Fog
  module AWS
    class RDS
      class ClusterSnapshots < Fog::Collection
        attribute :cluster
        attribute :filters
        model Fog::AWS::RDS::Snapshot

        def initialize(attributes)
          self.filters ||= {}
          if attributes[:cluster]
            filters[:identifier] = attributes[:cluster].id
          end

          if attributes[:type]
            filters[:type] = attributes[:type]
          end
          super
        end

        def all(filters_arg = filters)
          filters.merge!(filters_arg)

          page = service.describe_db_cluster_snapshots(filters).body['DescribeDBClusterSnapshotsResult']
          filters[:marker] = page['Marker']
          load(page['DBClusterSnapshots'])
        end

        def get(identity)
          data = service.describe_db_cluster_snapshots(:snapshot_id => identity).body['DescribeDBClusterSnapshotsResult']['DBClusterSnapshots'].first
          new(data) # data is an attribute hash
        rescue Fog::AWS::RDS::NotFound
          nil
        end

        def create(params={})
          if cluster
            super(params.merge(:cluster_id => cluster.id))
          else
            super(params)
          end
        end
      end
    end
  end
end
