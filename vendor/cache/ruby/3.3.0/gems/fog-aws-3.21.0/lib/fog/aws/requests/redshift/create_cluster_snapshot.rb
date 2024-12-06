module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/cluster_snapshot'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :snapshot_identifier - required - (String)
        #    A unique identifier for the snapshot that you are requesting. This identifier
        #    must be unique for all snapshots within the AWS account. Constraints: Cannot be
        #    null, empty, or blank Must contain from 1 to 255 alphanumeric characters or
        #    hyphens First character must be a letter Cannot end with a hyphen or contain two
        #    consecutive hyphens Example: my-snapshot-id
        # * :cluster_identifier - required - (String)
        #    The cluster identifier for which you want a snapshot.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_CreateClusterSnapshot.html
        def create_cluster_snapshot(options = {})
          snapshot_identifier  = options[:snapshot_identifier]
          cluster_identifier   = options[:cluster_identifier]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::ClusterSnapshot.new
          }

          params[:query]['Action']             = 'CreateClusterSnapshot'
          params[:query]['SnapshotIdentifier'] = snapshot_identifier if snapshot_identifier
          params[:query]['ClusterIdentifier']  = cluster_identifier if cluster_identifier

          request(params)
        end
      end
    end
  end
end
