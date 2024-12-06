module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/modify_db_instance'

        # modifies a database instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_ModifyDBInstance.html
        # ==== Parameters
        # * DBInstanceIdentifier <~String> - name of the db instance to modify
        # * ApplyImmediately <~Boolean> - whether to apply the changes immediately or wait for the next maintenance window
        #
        # * AllocatedStorage  <~Integer> Storage space, in GB
        # * AllowMajorVersionUpgrade <~Boolean> Must be set to true if EngineVersion specifies a different major version
        # * AutoMinorVersionUpgrade <~Boolean> Indicates that minor version upgrades will be applied automatically to the DB Instance during the maintenance window
        # * BackupRetentionPeriod  <~Integer> 0-8 The number of days to retain automated backups.
        # * DBInstanceClass <~String> The new compute and memory capacity of the DB Instanc
        # * DBParameterGroupName <~String> The name of the DB Parameter Group to apply to this DB Instance
        # * DBSecurityGroups <~Array> A list of DB Security Groups to authorize on this DB Instance
        # * EngineVersion <~String> The version number of the database engine to upgrade to.
        # * Iops <~Integer> IOPS rate
        # * MasterUserPassword  <~String> The new password for the DB Instance master user
        # * MultiAZ <~Boolean> Specifies if the DB Instance is a Multi-AZ deployment
        # * PreferredBackupWindow <~String> The daily time range during which automated backups are created if automated backups are enabled
        # * PreferredMaintenanceWindow <~String> The weekly time range (in UTC) during which system maintenance can occur, which may result in an outage
        # * VpcSecurityGroups <~Array> A list of VPC Security Group IDs to authorize on this DB instance
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def modify_db_instance(db_name, apply_immediately, options={})
          if security_groups = options.delete('DBSecurityGroups')
            options.merge!(Fog::AWS.indexed_param('DBSecurityGroups.member.%d', [*security_groups]))
          end

          if vpc_security_groups = options.delete('VpcSecurityGroups')
            options.merge!(Fog::AWS.indexed_param('VpcSecurityGroupIds.member.%d', [*vpc_security_groups]))
          end

          request({
            'Action'               => 'ModifyDBInstance',
            'DBInstanceIdentifier' => db_name,
            'ApplyImmediately'     => apply_immediately,
            :parser                => Fog::Parsers::AWS::RDS::ModifyDBInstance.new
          }.merge(options))
        end
      end

      class Mock
        def modify_db_instance(db_name, apply_immediately, _options={})
          options = _options.dup
          response = Excon::Response.new
          if server = self.data[:servers][db_name]
            if server["DBInstanceStatus"] != "available"
              raise Fog::AWS::RDS::NotFound.new("DBInstance #{db_name} not available for modification")
            else
              self.data[:modify_time] = Time.now
              # TODO verify the params options
              # if apply_immediately is false, all the options go to pending_modified_values and then apply and clear after either
              # a reboot or the maintainance window
              #if apply_immediately
              #  modified_server = server.merge(options)
              #else
              #  modified_server = server["PendingModifiedValues"].merge!(options) # it appends
              #end
              if options["NewDBInstanceIdentifier"]
                options["DBInstanceIdentifier"] = options.delete("NewDBInstanceIdentifier")
                options["Endpoint"]             = {"Port" => server["Endpoint"]["Port"], "Address"=> Fog::AWS::Mock.rds_address(options["DBInstanceIdentifier"],region)}
              end

              rds_security_groups = self.data[:security_groups].values
              ec2_security_groups = Fog::AWS::Compute::Mock.data[@region][@aws_access_key_id][:security_groups].values

              db_security_group_names = Array(options.delete("DBSecurityGroups"))
              db_security_groups = db_security_group_names.inject([]) do |r, group_name|
                unless rds_security_groups.find { |sg| sg["DBSecurityGroupName"] == group_name }
                  raise Fog::AWS::RDS::Error.new("InvalidParameterValue => Invalid security group , groupId= , groupName=#{group_name}")
                end
                r << {"Status" => "active", "DBSecurityGroupName" => group_name }
              end

              vpc_security_groups = Array(options.delete("VpcSecurityGroups")).inject([]) do |r, group_id|
                unless ec2_security_groups.find { |sg| sg["groupId"] == group_id }
                  raise Fog::AWS::RDS::Error.new("InvalidParameterValue => Invalid security group , groupId=#{group_id} , groupName=")
                end

                r << {"Status" => "active", "VpcSecurityGroupId" => group_id }
              end

              options.merge!(
                "DBSecurityGroups"  => db_security_groups,
                "VpcSecurityGroups" => vpc_security_groups
              )

              self.data[:servers][db_name]["PendingModifiedValues"].merge!(options) # it appends
              self.data[:servers][db_name]["DBInstanceStatus"] = "modifying"
              response.status = 200
              response.body = {
                "ResponseMetadata"       => { "RequestId"  => Fog::AWS::Mock.request_id },
                "ModifyDBInstanceResult" => { "DBInstance" => self.data[:servers][db_name] }
              }
              response

            end
          else
            raise Fog::AWS::RDS::NotFound.new("DBInstance #{db_name} not found")
          end
        end
      end
    end
  end
end
