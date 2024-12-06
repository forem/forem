module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/cluster'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_identifier - required - (String)
        #    The identifier of the cluster that will be created from restoring the snapshot.
        #    Constraints: Must contain from 1 to 63 alphanumeric characters or hyphens.
        #    Alphabetic characters must be lowercase. First character must be a letter. Cannot
        #    end with a hyphen or contain two consecutive hyphens. Must be unique for all
        #    clusters within an AWS account.
        # * :snapshot_identifier - required - (String)
        #    The name of the snapshot from which to create the new cluster. This parameter
        #    isn't case sensitive. Example: my-snapshot-id
        # * :snapshot_cluster_identifier - (String)
        # * :port - (Integer)
        #    The port number on which the cluster accepts connections. Default: The same port
        #    as the original cluster. Constraints: Must be between 1115 and 65535.
        # * :availability_zone - (String)
        #    The Amazon EC2 Availability Zone in which to restore the cluster. Default: A
        #    random, system-chosen Availability Zone. Example: us-east-1a
        # * :allow_version_upgrade - (Boolean)
        #    If true , upgrades can be applied during the maintenance window to the Amazon
        #    Redshift engine that is running on the cluster. Default: true
        # * :cluster_subnet_group_name - (String)
        #    The name of the subnet group where you want to cluster restored. A snapshot of
        #    cluster in VPC can be restored only in VPC. Therefore, you must provide subnet
        #    group name where you want the cluster restored.
        # * :publicly_accessible - (Boolean)
        #    If true , the cluster can be accessed from a public network.
        # * :owner_account - (String)
        #    The AWS customer account used to create or copy the snapshot. Required if you are
        #    restoring a snapshot you do not own, optional if you own the snapshot.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_RestoreFromClusterSnapshot.html
        def restore_from_cluster_snapshot(options = {})
          cluster_identifier           = options[:cluster_identifier]
          snapshot_identifier          = options[:snapshot_identifier]
          snapshot_cluster_identifier  = options[:snapshot_cluster_identifier]
          port                         = options[:port]
          availability_zone            = options[:availability_zone]
          allow_version_upgrade        = options[:allow_version_upgrade]
          cluster_subnet_group_name    = options[:cluster_subnet_group_name]
          publicly_accessible          = options[:publicly_accessible]
          owner_account                = options[:owner_account]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::Cluster.new
          }

          params[:query]['Action']                    = 'RestoreFromClusterSnapshot'
          params[:query]['ClusterIdentifier']         = cluster_identifier if cluster_identifier
          params[:query]['SnapshotIdentifier']        = snapshot_identifier if  snapshot_identifier
          params[:query]['SnapshotClusterIdentifier'] = snapshot_cluster_identifier if snapshot_cluster_identifier
          params[:query]['Port']                      = port if port
          params[:query]['AvailabilityZone']          = availability_zone if availability_zone
          params[:query]['AllowVersionUpgrade']       = allow_version_upgrade if allow_version_upgrade
          params[:query]['ClusterSubnetGroupName']    = cluster_subnet_group_name if cluster_subnet_group_name
          params[:query]['PubliclyAccessible']        = publicly_accessible if publicly_accessible
          params[:query]['OwnerAccount']              = owner_account if owner_account
          request(params)
        end
      end
    end
  end
end
