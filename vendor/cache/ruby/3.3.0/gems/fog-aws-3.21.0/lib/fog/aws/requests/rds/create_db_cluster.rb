module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/create_db_cluster'

        # Create a db cluster
        #
        # @see http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBCluster.html
        #
        # ==== Parameters ====
        # * AvailabilityZones<~Array> - A list of EC2 Availability Zones that instances in the DB cluster can be created in
        # * BackupRetentionPeriod<~String> - The number of days for which automated backups are retained
        # * CharacterSetName<~String> - A value that indicates that the DB cluster should be associated with the specified CharacterSet
        # * DatabaseName<~String> - The name for your database of up to 8 alpha-numeric characters. If you do not provide a name, Amazon RDS will not create a database in the DB cluster you are creating
        # * DBClusterIdentifier<~String> - The DB cluster identifier. This parameter is stored as a lowercase string
        # * DBClusterParameterGroupName<~String> - The name of the DB cluster parameter group to associate with this DB cluster
        # * DBSubnetGroupName<~String> - A DB subnet group to associate with this DB cluster
        # * Engine<~String> - The name of the database engine to be used for this DB cluster
        # * EngineVersion<~String> - The version number of the database engine to use
        # * KmsKeyId<~String> - The KMS key identifier for an encrypted DB cluster
        # * MasterUsername<~String> - The name of the master user for the client DB cluster
        # * MasterUserPassword<~String> - The password for the master database user
        # * OptionGroupName<~String> - A value that indicates that the DB cluster should be associated with the specified option group
        # * Port<~Integer> - The port number on which the instances in the DB cluster accept connections
        # * PreferredBackupWindow<~String> - The daily time range during which automated backups are created if automated backups are enabled using the BackupRetentionPeriod parameter
        # * PreferredMaintenanceWindow<~String> - The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC)
        # * StorageEncrypted<~Boolean> - Specifies whether the DB cluster is encrypted
        # * Tags<~Array> - A list of tags
        # * VpcSecurityGroups<~Array> - A list of EC2 VPC security groups to associate with this DB cluster
        #
        # ==== Returns ====
        # * response<~Excon::Response>:
        #   * body<~Hash>:

        def create_db_cluster(cluster_name, options={})
          if security_groups = options.delete('VpcSecurityGroups')
            options.merge!(Fog::AWS.indexed_param('VpcSecurityGroupIds.member.%d', [*security_groups]))
          end

          request({
            'Action'              => 'CreateDBCluster',
            'DBClusterIdentifier' => cluster_name,
            :parser               => Fog::Parsers::AWS::RDS::CreateDBCluster.new,
          }.merge(options))
        end
      end

      class Mock
        def create_db_cluster(cluster_name, options={})
          response = Excon::Response.new
          if self.data[:clusters][cluster_name]
            raise Fog::AWS::RDS::IdentifierTaken.new("DBClusterAlreadyExists")
          end

          required_params = %w(Engine MasterUsername MasterUserPassword)
          required_params.each do |key|
            unless options.key?(key) && options[key] && !options[key].to_s.empty?
              raise Fog::AWS::RDS::NotFound.new("The request must contain the parameter #{key}")
            end
          end

          vpc_security_groups = Array(options.delete("VpcSecurityGroups")).map do |group_id|
            {"VpcSecurityGroupId" => group_id }
          end

          data = {
            'AllocatedStorage'           => "1",
            'BackupRetentionPeriod'      => (options["BackupRetentionPeriod"] || 35).to_s,
            'ClusterCreateTime'          => Time.now,
            'DBClusterIdentifier'        => cluster_name,
            'DBClusterMembers'           => [],
            'DBClusterParameterGroup'    => options['DBClusterParameterGroup'] || "default.aurora5.6",
            'DBSubnetGroup'              => options["DBSubnetGroup"] || "default",
            'Endpoint'                   => "#{cluster_name}.cluster-#{Fog::Mock.random_hex(8)}.#{@region}.rds.amazonaws.com",
            'Engine'                     => options["Engine"] || "aurora5.6",
            'EngineVersion'              => options["EngineVersion"] || "5.6.10a",
            'MasterUsername'             => options["MasterUsername"],
            'Port'                       => options["Port"] || "3306",
            'PreferredBackupWindow'      => options["PreferredBackupWindow"] || "04:45-05:15",
            'PreferredMaintenanceWindow' => options["PreferredMaintenanceWindow"] || "sat:05:56-sat:06:26",
            'Status'                     => "available",
            'StorageEncrypted'           => options["StorageEncrypted"] || false,
            'VpcSecurityGroups'          => vpc_security_groups,
          }

          self.data[:clusters][cluster_name] = data
          response.body = {
            "ResponseMetadata" =>      { "RequestId" => Fog::AWS::Mock.request_id },
            "CreateDBClusterResult" => { "DBCluster" => data.dup.reject { |k,v| k == 'ClusterCreateTime' } }
          }
          response.status = 200
          response
        end
      end
    end
  end
end
