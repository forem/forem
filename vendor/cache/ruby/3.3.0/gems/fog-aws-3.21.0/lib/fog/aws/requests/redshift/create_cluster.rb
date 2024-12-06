module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/cluster'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :db_name - (String)
        #    The name of the first database to be created when the cluster is created. To create
        #    additional databases after the cluster is created, connect to the cluster with a SQL
        #    client and use SQL commands to create a database. Default: dev Constraints: Must
        #    contain 1 to 64 alphanumeric characters. Must contain only lowercase letters.
        # * :cluster_identifier - required - (String)
        #    A unique identifier for the cluster. You use this identifier to refer to the cluster
        #    for any subsequent cluster operations such as deleting or modifying. Must be unique
        #    for all clusters within an AWS account. Example: myexamplecluster
        # * :cluster_type - (String)
        #    Type of the cluster. When cluster type is specified as single-node, the NumberOfNodes
        #    parameter is not required. multi-node, the NumberOfNodes parameter is required. Valid
        #    Values: multi-node | single-node Default: multi-node
        # * :node_type - required - (String)
        #    The node type to be provisioned. Valid Values: dw.hs1.xlarge | dw.hs1.8xlarge.
        # * :master_username - required - (String)
        #    The user name associated with the master user account for the cluster that is being
        #    created. Constraints: Must be 1 - 128 alphanumeric characters. First character must
        #    be a letter. Cannot be a reserved word.
        # * :master_user_password - required - (String)
        #    The password associated with the master user account for the cluster that is being
        #    created. Constraints: Must be between 8 and 64 characters in length. Must contain at
        #    least one uppercase letter. Must contain at least one lowercase letter. Must contain
        #    one number.
        # * :cluster_security_groups - (Array<String>)
        #    A list of security groups to be associated with this cluster. Default: The default
        #    cluster security group for Amazon Redshift.
        # * :vpc_security_group_ids - (Array<String>)
        #    A list of Virtual Private Cloud (VPC) security groups to be associated with the
        #    cluster. Default: The default VPC security group is associated with the cluster.
        # * :cluster_subnet_group_name - (String)
        #    The name of a cluster subnet group to be associated with this cluster. If this
        #    parameter is not provided the resulting cluster will be deployed outside virtual
        #    private cloud (VPC).
        # * :availability_zone - (String)
        #    The EC2 Availability Zone (AZ) in which you want Amazon Redshift to provision the
        #    cluster. Default: A random, system-chosen Availability Zone in the region that is
        #    specified by the endpoint. Example: us-east-1d Constraint: The specified
        #    Availability Zone must be in the same region as the current endpoint.
        # * :preferred_maintenance_window - (String)
        #    The weekly time range (in UTC) during which automated cluster maintenance can occur.
        #    Format: ddd:hh24:mi-ddd:hh24:mi Default: A 30-minute window selected at random from
        #    an 8-hour block of time per region, occurring on a random day of the week.
        #    Constraints: Minimum 30-minute window.
        # * :cluster_parameter_group_name - (String)
        #    The name of the parameter group to be associated with this cluster. Default: The
        #    default Amazon Redshift cluster parameter group. Constraints: Must be 1 to 255
        #    alphanumeric characters or hyphens. First character must be a letter. Cannot end
        #    with a hyphen or contain two consecutive hyphens.
        # * :automated_snapshot_retention_period - (Integer)
        #    Number of days that automated snapshots are retained. If the value is 0, automated
        #    snapshots are disabled.  Default: 1 Constraints: Must be a value from 0 to 35.
        # * :port - (Integer)
        #    The port number on which the cluster accepts incoming connections. Default: 5439
        #    Valid Values: 1150-65535
        # * :cluster_version - (String)
        #    The version of the Amazon Redshift engine software that you want to deploy on the
        #    cluster. The version selected runs on all the nodes in the cluster. Constraints:
        #    Only version 1.0 is currently available. Example: 1.0
        # * :allow_version_upgrade - (Boolean)
        #    If `true` , upgrades can be applied during the maintenance window to the Amazon
        #    Redshift engine that is running on the cluster. Default:  `true`
        # * :number_of_nodes - (Integer)
        #    The number of compute nodes in the cluster. This parameter is required when the
        #    ClusterType parameter is specified as multi-node. If you don't specify this parameter,
        #    you get a single-node cluster. When requesting a multi-node cluster, you must specify
        #    the number of nodes that you want in the cluster. Default: 1 Constraints: Value must
        #    be at least 1 and no more than 100.
        # * :publicly_accessible - (Boolean)
        #    If `true` , the cluster can be accessed from a public network.
        # * :encrypted - (Boolean)
        #    If `true` , the data in cluster is encrypted at rest. Default:  `false`

        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_CreateCluster.html
        def create_cluster(options = {})
          db_name                             = options[:db_name]
          cluster_identifier                  = options[:cluster_identifier]
          cluster_type                        = options[:cluster_type]
          node_type                           = options[:node_type]
          master_username                     = options[:master_username]
          master_user_password                = options[:master_user_password]
          cluster_subnet_group_name           = options[:cluster_subnet_group_name]
          availability_zone                   = options[:availability_zone]
          preferred_maintenance_window        = options[:preferred_maintenance_window]
          cluster_parameter_group_name        = options[:cluster_parameter_group_name]
          automated_snapshot_retention_period = options[:automated_snapshot_retention_period]
          port                                = options[:port]
          cluster_version                     = options[:cluster_version]
          allow_version_upgrade               = options[:allow_version_upgrade]
          number_of_nodes                     = options[:number_of_nodes]
          publicly_accessible                 = options[:publicly_accessible]
          encrypted                           = options[:encrypted]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::Cluster.new
          }

          if cluster_security_groups = options.delete(:ClusterSecurityGroups)
            params[:query].merge!(Fog::AWS.indexed_param('ClusterSecurityGroups.member.%d', [*cluster_security_groups]))
          end

          if vpc_security_group_ids = options.delete(:VpcSecurityGroupIds)
            params[:query].merge!(Fog::AWS.indexed_param('VpcSecurityGroupIds.member.%d', [*vpc_security_group_ids]))
          end

          params[:query]['Action']                           = 'CreateCluster'
          params[:query]['DBName']                           = db_name if db_name
          params[:query]['ClusterIdentifier']                = cluster_identifier if cluster_identifier
          params[:query]['ClusterType']                      = cluster_type if cluster_type
          params[:query]['NodeType']                         = node_type if node_type
          params[:query]['MasterUsername']                   = master_username if master_username
          params[:query]['MasterUserPassword']               = master_user_password if master_user_password
          params[:query]['ClusterSecurityGroups']            = cluster_security_groups if cluster_security_groups
          params[:query]['VpcSecurityGroupIds']              = vpc_security_group_ids if vpc_security_group_ids
          params[:query]['ClusterSubnetGroupName']           = cluster_subnet_group_name if cluster_subnet_group_name
          params[:query]['AvailabilityZone']                 = availability_zone if availability_zone
          params[:query]['PreferredMaintenanceWindow']       = preferred_maintenance_window if preferred_maintenance_window
          params[:query]['ClusterParameterGroupName']        = cluster_parameter_group_name if cluster_parameter_group_name
          params[:query]['AutomatedSnapshotRetentionPeriod'] = automated_snapshot_retention_period if automated_snapshot_retention_period
          params[:query]['Port']                             = port if port
          params[:query]['ClusterVersion']                   = cluster_version if cluster_version
          params[:query]['AllowVersionUpgrade']              = allow_version_upgrade if allow_version_upgrade
          params[:query]['NumberOfNodes']                    = number_of_nodes if number_of_nodes
          params[:query]['PubliclyAccessible']               = publicly_accessible if publicly_accessible
          params[:query]['Encrypted']                        = encrypted if encrypted

          request(params)
        end
      end
    end
  end
end
