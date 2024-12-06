module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/create_db_instance'

        # Create a db instance
        #
        # @param DBInstanceIdentifier [String] name of the db instance to modify
        # @param AllocatedStorage [Integer] Storage space, in GB
        # @param AutoMinorVersionUpgrade [Boolean] Indicates that minor version upgrades will be applied automatically to the DB Instance during the maintenance window
        # @param AvailabilityZone [String] The availability zone to create the instance in
        # @param BackupRetentionPeriod [Integer] 0-8 The number of days to retain automated backups.
        # @param DBInstanceClass [String] The new compute and memory capacity of the DB Instance
        # @param DBName [String] The name of the database to create when the DB Instance is created
        # @param DBParameterGroupName [String] The name of the DB Parameter Group to apply to this DB Instance
        # @param DBSecurityGroups [Array] A list of DB Security Groups to authorize on this DB Instance
        # @param Engine [String] The name of the database engine to be used for this instance.
        # @param EngineVersion [String] The version number of the database engine to use.
        # @param Iops [Integer] IOPS rate
        # @param MasterUsername [String] The db master user
        # @param MasterUserPassword [String] The new password for the DB Instance master user
        # @param MultiAZ [Boolean] Specifies if the DB Instance is a Multi-AZ deployment
        # @param Port [Integer] The port number on which the database accepts connections.
        # @param PreferredBackupWindow [String] The daily time range during which automated backups are created if automated backups are enabled
        # @param PreferredMaintenanceWindow [String] The weekly time range (in UTC) during which system maintenance can occur, which may result in an outage
        # @param DBSubnetGroupName [String] The name, if any, of the VPC subnet for this RDS instance
        # @param PubliclyAccessible [Boolean] Whether an RDS instance inside of the VPC subnet should have a public-facing endpoint
        # @param VpcSecurityGroups [Array] A list of VPC Security Groups to authorize on this DB instance
        # @param StorageType [string] Specifies storage type to be associated with the DB Instance.  Valid values: standard | gp2 | io1
        #
        # @return [Excon::Response]:
        #   * body [Hash]:
        #
        # @see http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html
        def create_db_instance(db_name, options={})
          if security_groups = options.delete('DBSecurityGroups')
            options.merge!(Fog::AWS.indexed_param('DBSecurityGroups.member.%d', [*security_groups]))
          end

          if vpc_security_groups = options.delete('VpcSecurityGroups')
            options.merge!(Fog::AWS.indexed_param('VpcSecurityGroupIds.member.%d', [*vpc_security_groups]))
          end

          request({
            'Action'               => 'CreateDBInstance',
            'DBInstanceIdentifier' => db_name,
            :parser                => Fog::Parsers::AWS::RDS::CreateDBInstance.new,
          }.merge(options))
        end
      end

      class Mock
        def create_db_instance(db_name, options={})
          response = Excon::Response.new
          if self.data[:servers] and self.data[:servers][db_name]
            # I don't know how to raise an exception that contains the excon data
            #response.status = 400
            #response.body = {
            #  'Code' => 'DBInstanceAlreadyExists',
            #  'Message' => "DB Instance already exists"
            #}
            #return response
            raise Fog::AWS::RDS::IdentifierTaken.new("DBInstanceAlreadyExists #{response.body.to_s}")
          end

          # These are the required parameters according to the API
          required_params = %w(DBInstanceClass Engine)
          required_params += %w{AllocatedStorage DBInstanceClass Engine MasterUserPassword MasterUsername } unless options["DBClusterIdentifier"]
          required_params.each do |key|
            unless options.key?(key) and options[key] and !options[key].to_s.empty?
              #response.status = 400
              #response.body = {
              #  'Code' => 'MissingParameter',
              #  'Message' => "The request must contain the parameter #{key}"
              #}
              #return response
              raise Fog::AWS::RDS::NotFound.new("The request must contain the parameter #{key}")
            end
          end

          if !!options["MultiAZ"] && !!options["AvailabilityZone"]
            raise Fog::AWS::RDS::InvalidParameterCombination.new('Requesting a specific availability zone is not valid for Multi-AZ instances.')
          end

          ec2 = Fog::AWS::Compute::Mock.data[@region][@aws_access_key_id]

          db_parameter_groups     = if pg_name = options.delete("DBParameterGroupName")
                                      group = self.data[:parameter_groups][pg_name]
                                      if group
                                        [{"DBParameterGroupName" => pg_name, "ParameterApplyStatus" => "in-sync" }]
                                      else
                                        raise Fog::AWS::RDS::NotFound.new("Parameter group does not exist")
                                      end
                                    else
                                      [{ "DBParameterGroupName" => "default.mysql5.5", "ParameterApplyStatus" => "in-sync" }]
                                    end
          db_security_group_names = Array(options.delete("DBSecurityGroups"))
          rds_security_groups     = self.data[:security_groups].values
          ec2_security_groups     = ec2[:security_groups].values
          vpc                     = !ec2[:account_attributes].find { |h| "supported-platforms" == h["attributeName"] }["values"].include?("EC2")

          db_security_groups = db_security_group_names.map do |group_name|
            unless rds_security_groups.find { |sg| sg["DBSecurityGroupName"] == group_name }
              raise Fog::AWS::RDS::Error.new("InvalidParameterValue => Invalid security group , groupId= , groupName=#{group_name}")
            end

            {"Status" => "active", "DBSecurityGroupName" => group_name }
          end

          if !vpc && db_security_groups.empty?
            db_security_groups << { "Status" => "active", "DBSecurityGroupName" => "default" }
          end

          vpc_security_groups = Array(options.delete("VpcSecurityGroups")).map do |group_id|
            unless ec2_security_groups.find { |sg| sg["groupId"] == group_id }
              raise Fog::AWS::RDS::Error.new("InvalidParameterValue => Invalid security group , groupId=#{group_id} , groupName=")
            end

            {"Status" => "active", "VpcSecurityGroupId" => group_id }
          end

          if options["Engine"] == "aurora" && ! options["DBClusterIdentifier"]
            raise Fog::AWS::RDS::Error.new("InvalidParameterStateValue => Standalone instances for this engine are not supported")
          end

          if cluster_id = options["DBClusterIdentifier"]
            if vpc_security_groups.any?
              raise Fog::AWS::RDS::Error.new("InvalidParameterCombination => The requested DB Instance will be a member of a DB Cluster and its vpc security group should not be set directly.")
            end

            if options["MultiAZ"]
              raise Fog::AWS::RDS::Error.new("InvalidParameterCombination => VPC Multi-AZ DB Instances are not available for engine: aurora")
            end

            %w(AllocatedStorage BackupRetentionPeriod MasterUsername MasterUserPassword).each do |forbidden|
              raise Fog::AWS::RDS::Error.new("InvalidParameterCombination => The requested DB Instance will be a member of a DB Cluster and its #{forbidden} should not be set directly.") if options[forbidden]
            end

            options["StorageType"] = "aurora"

            cluster = self.data[:clusters][cluster_id]

            member = {"DBInstanceIdentifier" => db_name, "master" => cluster['DBClusterMembers'].empty?}
            cluster['DBClusterMembers'] << member
            self.data[:clusters][cluster_id] = cluster
          end

          data = {
            "AllocatedStorage"                 => options["AllocatedStorage"],
            "AutoMinorVersionUpgrade"          => options["AutoMinorVersionUpgrade"].nil? ? true : options["AutoMinorVersionUpgrade"],
            "AvailabilityZone"                 => options["AvailabilityZone"],
            "BackupRetentionPeriod"            => options["BackupRetentionPeriod"] || 1,
            "CACertificateIdentifier"          => "rds-ca-2015",
            "DBClusterIdentifier"              => options["DBClusterIdentifier"],
            "DBInstanceClass"                  => options["DBInstanceClass"],
            "DBInstanceIdentifier"             => db_name,
            "DBInstanceStatus"                 =>"creating",
            "DBName"                           => options["DBName"],
            "DBParameterGroups"                => db_parameter_groups,
            "DBSecurityGroups"                 => db_security_groups,
            "DBSubnetGroupName"                => options["DBSubnetGroupName"],
            "Endpoint"                         =>{},
            "Engine"                           => options["Engine"],
            "EngineVersion"                    => options["EngineVersion"] || "5.5.12",
            "InstanceCreateTime"               => nil,
            "Iops"                             => options["Iops"],
            "LicenseModel"                     => "general-public-license",
            "MasterUsername"                   => cluster_id ? cluster["MasterUsername"] : options["MasterUsername"],
            "MultiAZ"                          => !!options["MultiAZ"],
            "PendingModifiedValues"            => { "MasterUserPassword" => "****" }, # This clears when is available
            "PreferredBackupWindow"            => options["PreferredBackupWindow"] || "08:00-08:30",
            "PreferredMaintenanceWindow"       => options["PreferredMaintenanceWindow"] || "mon:04:30-mon:05:00",
            "PubliclyAccessible"               => !!options["PubliclyAccessible"],
            "ReadReplicaDBInstanceIdentifiers" => [],
            "StorageEncrypted"                 => cluster_id ? cluster["StorageEncrypted"] : (options["StorageEncrypted"] || false),
            "StorageType"                      => options["StorageType"] || "standard",
            "VpcSecurityGroups"                => vpc_security_groups,
          }

          self.data[:servers][db_name] = data
          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            "CreateDBInstanceResult"=> {"DBInstance"=> data}
          }
          response.status = 200
          # This values aren't showed at creating time but at available time
          self.data[:servers][db_name]["InstanceCreateTime"] = Time.now
          self.data[:tags] ||= {}
          self.data[:tags][db_name] = {}
          response
        end
      end
    end
  end
end
