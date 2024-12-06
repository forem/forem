module Fog
  module Parsers
    module AWS
      module RDS
        class DbParser < Fog::Parsers::Base
          def reset
            @db_instance = fresh_instance
          end

          def fresh_instance
            {'PendingModifiedValues' => [], 'DBSecurityGroups' => [], 'ReadReplicaDBInstanceIdentifiers' => [], 'Endpoint' => {}, 'DBSubnetGroup' => {}}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'PendingModifiedValues'
              @in_pending_modified_values = true
              @pending_modified_values = {}
            when 'DBSecurityGroups'
              @in_db_security_groups = true
              @db_security_groups = []
            when 'DBSecurityGroup'
              @db_security_group = {}
            when 'Endpoint'
              @in_endpoint = true
              @endpoint = {}
            when 'DBParameterGroup'
              @db_parameter_group = {}
            when 'DBParameterGroups'
              @in_db_parameter_groups = true
              @db_parameter_groups = []
            when 'VpcSecurityGroupMembership'
              @vpc_security_group = {}
            when 'VpcSecurityGroups'
              @in_vpc_security_groups = true
              @vpc_security_groups = []
            when 'DBSubnetGroup'
              @in_db_subnet_group = true
              @db_subnet_group = {}
            when 'Subnets'
              @in_subnets = true
              @subnets = []
            when 'Subnet'
              @subnet = {}
            when 'SubnetAvailabilityZone'
              @in_subnet_availability_zone = true
              @subnet_availability_zone = {}
            end
          end

          def end_element(name)
            case name

            when 'LatestRestorableTime', 'InstanceCreateTime'
              @db_instance[name] = Time.parse value
            when 'Engine', 'DBInstanceStatus', 'DBInstanceIdentifier',
              'PreferredBackupWindow', 'PreferredMaintenanceWindow',
              'AvailabilityZone', 'MasterUsername', 'DBName', 'LicenseModel',
              'DBSubnetGroupName', 'StorageType', 'KmsKeyId', 'TdeCredentialArn',
              'SecondaryAvailabilityZone', 'DbiResourceId', 'CACertificateIdentifier',
              'CharacterSetName', 'DbiResourceId', 'LicenseModel', 'KmsKeyId',
              'DBClusterIdentifier'
              @db_instance[name] = value
            when 'MultiAZ', 'AutoMinorVersionUpgrade', 'PubliclyAccessible',
              'StorageEncrypted', 'EnableIAMDatabaseAuthentication'
              @db_instance[name] = (value == 'true')
            when 'DBParameterGroups'
              @in_db_parameter_groups = false
              @db_instance['DBParameterGroups'] = @db_parameter_groups
            when 'DBParameterGroup'
              @db_parameter_groups << @db_parameter_group
              @db_parameter_group = {}
            when 'ParameterApplyStatus', 'DBParameterGroupName'
              if @in_db_parameter_groups
                @db_parameter_group[name] = value
              end
            when 'BackupRetentionPeriod', 'Iops', 'AllocatedStorage'
              if @in_pending_modified_values
                @pending_modified_values[name] = value.to_i
              else
                @db_instance[name] = value.to_i
              end
            when 'DBInstanceClass', 'EngineVersion', 'MasterUserPassword',
                'MultiAZ'
              if @in_pending_modified_values
                @pending_modified_values[name] = value
              else
                @db_instance[name] = value
              end
            when 'DBSecurityGroups'
              @in_db_security_groups = false
              @db_instance['DBSecurityGroups'] = @db_security_groups
            when 'DBSecurityGroupName'
              @db_security_group[name]=value
            when 'DBSecurityGroup'
              @db_security_groups << @db_security_group
              @db_security_group = {}
            when 'VpcSecurityGroups'
              @in_vpc_security_groups = false
              @db_instance['VpcSecurityGroups'] = @vpc_security_groups
            when 'VpcSecurityGroupMembership'
              @vpc_security_groups << @vpc_security_group
              @vpc_security_group = {}
            when 'VpcSecurityGroupId'
              @vpc_security_group[name] = value
            when 'Status'
              # Unfortunately, status is used in VpcSecurityGroupMemebership and
              # DBSecurityGroups
              if @in_db_security_groups
                @db_security_group[name]=value
              end
              if @in_vpc_security_groups
                @vpc_security_group[name] = value
              end
            when 'Address'
              @endpoint[name] = value
            when 'Port'
              if @in_pending_modified_values
                @pending_modified_values[name] = value.to_i
              elsif @in_endpoint
                @endpoint[name] = value.to_i
              end
            when 'PendingModifiedValues'
              @in_pending_modified_values = false
              @db_instance['PendingModifiedValues'] = @pending_modified_values
            when 'Endpoint'
              @in_endpoint = false
              @db_instance['Endpoint'] = @endpoint
            when 'ReadReplicaDBInstanceIdentifier'
              @db_instance['ReadReplicaDBInstanceIdentifiers'] << value
            when 'ReadReplicaSourceDBInstanceIdentifier'
              @db_instance['ReadReplicaSourceDBInstanceIdentifier'] = value
            when 'DBInstance'
              @db_instance = fresh_instance
            when 'DBSubnetGroup'
              @in_db_subnet_group = false
              @db_instance['DBSubnetGroup'] = @db_subnet_group
            when 'VpcId'
              if @in_db_subnet_group
                @db_subnet_group[name] = value
              end
            when 'Subnets'
              @in_subnets = false
              if @in_db_subnet_group
                @db_subnet_group['Subnets'] = @subnets
              end
            when 'Subnet'
              if @in_subnets
                @subnets << @subnet
              end
            when 'SubnetIdentifier', 'SubnetStatus'
              if @in_subnets
                @subnet[name] = value
              end
            when 'SubnetAvailabilityZone'
              @in_subnet_availability_zone = false
              @subnet['SubnetAvailabilityZone'] = @subnet_availability_zone
            when 'Name'
              if @in_subnet_availability_zone
                @subnet_availability_zone[name] = value
              end
            end
          end
        end
      end
    end
  end
end
