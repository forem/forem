module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/describe_db_clusters'

        # Describe all or specified db clusters
        # http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeDBClusters.html
        #
        # ==== Parameters ====
        # * DBClusterIdentifier<~String> - The user-supplied DB cluster identifier
        #
        # ==== Returns ====
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_db_clusters(identifier=nil, opts={})
          params = {}
          params['DBClusterIdentifier'] = identifier         if identifier
          params['Marker']              = opts[:marker]      if opts[:marker]
          params['MaxRecords']          = opts[:max_records] if opts[:max_records]

          request({
            'Action' => 'DescribeDBClusters',
            :parser  => Fog::Parsers::AWS::RDS::DescribeDBClusters.new
          }.merge(params))
        end
      end

      class Mock
        def describe_db_clusters(identifier=nil, opts={})
          response    = Excon::Response.new
          cluster_set = []

          if identifier
            if cluster = self.data[:clusters][identifier]
              cluster_set << cluster
            else
              raise Fog::AWS::RDS::NotFound.new("DBCluster #{identifier} not found")
            end
          else
            cluster_set = self.data[:clusters].values
          end

          response.status = 200
          response.body = {
            "ResponseMetadata"         => { "RequestId"  => Fog::AWS::Mock.request_id },
            "DescribeDBClustersResult" => { "DBClusters" => cluster_set }
          }
          response
        end
      end
    end
  end
end
