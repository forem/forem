module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/cluster'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_identifier - required - (String)
        #    A unique identifier for the cluster. You use this identifier to refer to the cluster
        #    for any subsequent cluster operations such as deleting or modifying. Must be unique
        #    for all clusters within an AWS account. Example: myexamplecluster
        # * :skip_final_cluster_snapshot - (Boolean)
        #    Determines whether a final snapshot of the cluster is created before Amazon Redshift
        #    deletes the cluster. If  `true` , a final cluster snapshot is not created. If `false`,
        #    a final cluster snapshot is created before the cluster is deleted. The
        #    FinalClusterSnapshotIdentifier parameter must be specified if SkipFinalClusterSnapshot
        #    is `false` . Default:  `false`
        # * :final_cluster_snapshot_identifier - (String)
        #    The identifier of the final snapshot that is to be created immediately before deleting
        #    the cluster. If this parameter is provided, SkipFinalClusterSnapshot must be  `false`.
        #    Constraints: Must be 1 to 255 alphanumeric characters. First character must be a letter
        #    Cannot end with a hyphen or contain two consecutive hyphens.
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DeleteCluster.html
        def delete_cluster(options = {})
          cluster_identifier                = options[:cluster_identifier]
          final_cluster_snapshot_identifier = options[:final_cluster_snapshot_identifier]
          skip_final_cluster_snapshot       = options[:skip_final_cluster_snapshot]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::Cluster.new
          }

          params[:query]['Action']                           = 'DeleteCluster'
          params[:query]['ClusterIdentifier']                = cluster_identifier if cluster_identifier
          params[:query]['FinalClusterSnapshotIdentifier']   = final_cluster_snapshot_identifier if final_cluster_snapshot_identifier
          params[:query]['SkipFinalClusterSnapshot']         = skip_final_cluster_snapshot if skip_final_cluster_snapshot
          request(params)
        end
      end
    end
  end
end
