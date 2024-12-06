module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/cluster_snapshot'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :snapshot_identifier - required - (String)
        #    The identifier of the snapshot that the account can no longer access.
        # * :snapshot_cluster_identifier - (String)
        # * :account_with_restore_access - required - (String)
        #    The identifier of the AWS customer account that can no longer restore the specified snapshot.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_RevokeSnapshotAccess.html
        def revoke_snapshot_access(options = {})
          snapshot_identifier         = options[:snapshot_identifier]
          snapshot_cluster_identifier = options[:snapshot_cluster_identifier]
          account_with_restore_access = options[:account_with_restore_access]

          path = "/"
          params = {
            :expects => 200,
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::ClusterSnapshot.new
          }

          params[:query]['Action']                    = 'RevokeSnapshotAccess'
          params[:query]['SnapshotIdentifier']        = snapshot_identifier if snapshot_identifier
          params[:query]['SnapshotClusterIdentifier'] = snapshot_cluster_identifier if snapshot_cluster_identifier
          params[:query]['AccountWithRestoreAccess']  = account_with_restore_access if account_with_restore_access

          request(params)
        end
      end
    end
  end
end
