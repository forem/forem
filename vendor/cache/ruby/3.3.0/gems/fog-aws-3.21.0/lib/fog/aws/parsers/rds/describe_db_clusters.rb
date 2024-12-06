module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_cluster_parser'

        class DescribeDBClusters < Fog::Parsers::AWS::RDS::DbClusterParser
          def reset
            @response = { 'DescribeDBClustersResult' => { 'DBClusters' => []}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs=[])
            super
          end

          def end_element(name)
            case name
            when 'DBCluster'
              @response['DescribeDBClustersResult']['DBClusters'] << @db_cluster
              @db_cluster = fresh_cluster
            when 'Marker'
              @response['DescribeDBClustersResult']['Marker'] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
