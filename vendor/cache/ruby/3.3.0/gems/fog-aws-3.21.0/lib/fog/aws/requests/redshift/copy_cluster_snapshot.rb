module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/cluster_snapshot'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :source_snapshot_identifier - required - (String)
        #    The identifier for the source snapshot. Constraints: Must be the identifier for
        #    a valid automated snapshot whose state is "available".
        # * :source_snapshot_cluster_identifier - (String)
        # * :target_snapshot_identifier - required - (String)
        #    The identifier given to the new manual snapshot. Constraints: Cannot be null,
        #    empty, or blank. Must contain from 1 to 255 alphanumeric characters or hyphens.
        #    First character must be a letter. Cannot end with a hyphen or contain two
        #    consecutive hyphens. Must be unique for the AWS account that is making the request.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_CopyClusterSnapshot.html
        def copy_cluster_snapshot(options = {})
          source_snapshot_identifier         = options[:source_snapshot_identifier]
          source_snapshot_cluster_identifier = options[:source_snapshot_cluster_identifier]
          target_snapshot_identifier         = options[:target_snapshot_identifier]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::ClusterSnapshot.new
          }

          params[:query]['Action']                          = 'CopyClusterSnapshot'
          params[:query]['SourceSnapshotIdentifier']        = source_snapshot_identifier if source_snapshot_identifier
          params[:query]['SourceSnapshotClusterIdentifier'] = source_snapshot_cluster_identifier if source_snapshot_cluster_identifier
          params[:query]['TargetSnapshotIdentifier']        = target_snapshot_identifier if target_snapshot_identifier

          request(params)
        end
      end
    end
  end
end
