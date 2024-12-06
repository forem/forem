module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_cluster_parser'

        class DeleteDBCluster < Fog::Parsers::AWS::RDS::DbClusterParser
          def reset
            @response = { 'DeleteDBClusterResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBCluster'
              @response['DeleteDBClusterResult']['DBCluster'] = @db_cluster
              @db_cluster = fresh_cluster
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
