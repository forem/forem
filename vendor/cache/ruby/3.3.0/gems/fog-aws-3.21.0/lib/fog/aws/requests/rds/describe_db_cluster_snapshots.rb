module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/describe_db_cluster_snapshots'

        # Describe all or specified db cluster snapshots
        # http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeDBClusterSnapshots.html
        #
        # ==== Parameters ====
        # * DBClusterIdentifier<~String> - A DB cluster identifier to retrieve the list of DB cluster snapshots for
        # * DBClusterSnapshotIdentifier<~String> - A specific DB cluster snapshot identifier to describe
        # * SnapshotType<~String> - The type of DB cluster snapshots that will be returned. Values can be automated or manual
        #
        # ==== Returns ====
        # * response<~Excon::Response>:
        #   * body<~Hash>:

        def describe_db_cluster_snapshots(opts={})
          params                                = {}
          params['SnapshotType']                = opts[:type]        if opts[:type]
          params['DBClusterIdentifier']         = opts[:identifier]  if opts[:identifier]
          params['DBClusterSnapshotIdentifier'] = opts[:snapshot_id] if opts[:snapshot_id]
          params['Marker']                      = opts[:marker]      if opts[:marker]
          params['MaxRecords']                  = opts[:max_records] if opts[:max_records]
          request({
            'Action' => 'DescribeDBClusterSnapshots',
            :parser  => Fog::Parsers::AWS::RDS::DescribeDBClusterSnapshots.new
          }.merge(params))
        end
      end

      class Mock
        def describe_db_cluster_snapshots(opts={})
          response = Excon::Response.new
          snapshots = self.data[:cluster_snapshots].values

          if opts[:identifier]
            snapshots = snapshots.select { |snapshot| snapshot['DBClusterIdentifier'] == opts[:identifier] }
          end

          if opts[:snapshot_id]
            snapshots = snapshots.select { |snapshot| snapshot['DBClusterSnapshotIdentifier'] == opts[:snapshot_id] }
            raise Fog::AWS::RDS::NotFound.new("DBClusterSnapshot #{opts[:snapshot_id]} not found") if snapshots.empty?
          end

          snapshots.each do |snapshot|
            case snapshot['Status']
            when 'creating'
              if Time.now - snapshot['SnapshotCreateTime'] > Fog::Mock.delay
                snapshot['Status'] = 'available'
              end
            end
          end

          response.status = 200
          response.body = {
            'ResponseMetadata'                 => { "RequestId"          => Fog::AWS::Mock.request_id },
            'DescribeDBClusterSnapshotsResult' => { 'DBClusterSnapshots' => snapshots }
          }
          response
        end
      end
    end
  end
end
