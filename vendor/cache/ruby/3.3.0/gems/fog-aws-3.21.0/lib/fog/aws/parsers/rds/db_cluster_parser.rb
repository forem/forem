module Fog
  module Parsers
    module AWS
      module RDS
        class DbClusterParser < Fog::Parsers::Base
          def reset
            @db_cluster = fresh_cluster
          end

          def fresh_cluster
            {'AvailabilityZones' => [], 'VpcSecurityGroups' => []}
          end

          def start_element(name, attrs=[])
            super
            case name
            when 'AvailabilityZones'
              @in_availability_zones = true
            when 'DBClusterMembers'
              @in_db_cluster_members = true
              @db_cluster_members = []
            when 'DBClusterMember'
              @db_cluster_member = {}
            when 'VpcSecurityGroupMembership'
              @vpc_security_group = {}
            when 'VpcSecurityGroups'
              @in_vpc_security_groups = true
              @vpc_security_groups = []
            end
          end

          def end_element(name)
            case name
            when 'Port', 'Engine', 'Status', 'BackupRetentionPeriod', 'DBSubnetGroup', 'EngineVersion', 'Endpoint', 'DBClusterParameterGroup', 'DBClusterIdentifier', 'PreferredBackupWindow', 'PreferredMaintenanceWindow', 'AllocatedStorage', 'MasterUsername'
              @db_cluster[name] = value
            when 'VpcSecurityGroups'
              @in_vpc_security_groups = false
              @db_cluster['VpcSecurityGroups'] = @vpc_security_groups
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
            when 'DBClusterMembers'
              @in_db_cluster_members = false
              @db_cluster['DBClusterMembers'] = @db_cluster_members
            when 'DBClusterMember'
              @db_cluster_members << @db_cluster_member
              @db_cluster_member = {}
            when 'IsClusterWriter'
              @db_cluster_member['master'] = value == "true"
            when 'DBInstanceIdentifier'
              @db_cluster_member[name] = value
            when 'DBCluster'
              @db_cluster = fresh_cluster
            end
          end
        end
      end
    end
  end
end
