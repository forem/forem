module Fog
  module Parsers
    module Redshift
      module AWS
        class ClusterParser < Fog::Parsers::Base
          # :cluster_identifier - (String)
          # :node_type - (String)
          # :cluster_status - (String)
          # :modify_status - (String)
          # :master_username - (String)
          # :db_name - (String)
          # :endpoint - (Hash)
          #   :address - (String)
          #   :port - (Integer)
          # :cluster_create_time - (Time)
          # :automated_snapshot_retention_period - (Integer)
          # :cluster_security_groups - (Array)
          #   :cluster_security_group_name - (String)
          #   :status - (String)
          # :vpc_security_groups - (Array)
          #   :vpc_security_group_id - (String)
          #   :status - (String)
          # :cluster_parameter_groups - (Array)
          #   :parameter_group_name - (String)
          #   :parameter_apply_status - (String)
          # :cluster_subnet_group_name - (String)
          # :vpc_id - (String)
          # :availability_zone - (String)
          # :preferred_maintenance_window - (String)
          # :pending_modified_values - (Hash)
          #   :master_user_password - (String)
          #   :node_type - (String)
          #   :number_of_nodes - (Integer)
          #   :cluster_type - (String)
          #   :cluster_version - (String)
          #   :automated_snapshot_retention_period - (Integer)
          # :cluster_version - (String)
          # :allow_version_upgrade - (Boolean)
          # :number_of_nodes - (Integer)
          # :publicly_accessible - (Boolean)
          # :encrypted - (Boolean)
          # :restore_status - (Hash)
          #   :status - (String)
          #   :current_restore_rate_in_mega_bytes_per_second - (Numeric)
          #   :snapshot_size_in_mega_bytes - (Integer)
          #   :progress_in_mega_bytes - (Integer)
          #   :elapsed_time_in_seconds - (Integer)
          #   :estimated_time_to_completion_in_seconds - (Integer)

          def reset
            @cluster = fresh_cluster
          end

          def fresh_cluster
            { 'ClusterParameterGroups' => [], 'ClusterSecurityGroups' => [], 'VpcSecurityGroups' => [],
              'EndPoint' => {}, 'PendingModifiedValues'=> {}, 'RestoreStatus' => {}}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ClusterSecurityGroups'
              @in_cluster_security_groups = true
              @cluster_security_group = {}
            when 'ClusterParameterGroups'
              @cluster_parameter_group = {}
            when 'VpcSecurityGroups'
              @in_vpc_security_groups = true
              @vpc_security_group = {}
            when 'PendingModifiedValues'
              @in_pending_modified_values = true
            end
          end

          def end_element(name)
            case name
            when 'AvailabilityZone', 'ClusterIdentifier', 'ClusterStatus', 'ClusterSubnetGroupName', 'DBName',
              'MasterUsername', 'ModifyStatus', 'PreferredMaintenanceWindow', 'VpcId'
              @cluster[name] = value
            when 'ClusterCreateTime'
              @cluster[name] = Time.parse(value)
            when 'AllowVersionUpgrade', 'Encrypted', 'PubliclyAccessible'
              @cluster[name] = (value == "true")
            when 'Address'
              @cluster['EndPoint'][name] = value
            when 'Port'
              @cluster['EndPoint'][name] = value.to_i
            when 'NodeType', 'ClusterVersion'
              if @in_pending_modified_values
                @cluster['PendingModifiedValues'][name] = value
              else
                @cluster[name] = value
              end
            when 'NumberOfNodes', 'AutomatedSnapshotRetentionPeriod'
              if @in_pending_modified_values
                @cluster['PendingModifiedValues'][name] = value.to_i
              else
                @cluster[name] = value.to_i
              end
            when 'MasterUserPassword', 'ClusterType'
              @cluster['PendingModifiedValues'][name] = value
            when 'Status'
              if @in_vpc_security_groups
                @vpc_security_group[name] = value
              elsif @in_cluster_security_groups
                @cluster_security_group[name] = value
              else
                @cluster['RestoreStatus'][name] = value
              end
            when 'ParameterGroupName', 'ParameterApplyStatus'
              @cluster_parameter_group[name] = value
            when 'ClusterSecurityGroupName'
              @cluster_security_group[name] = value
            when 'VpcSecurityGroupId'
              @vpc_security_group[name] = value
            when 'SnapshotSizeInMegaBytes', 'ProgressInMegaBytes', 'ElapsedTimeInSeconds', 'EstimatedTimeToCompletionInSeconds'
              @cluster['RestoreStatus'][name] = value.to_i
            when 'CurrentRestoreRateInMegaBytesPerSecond'
              @cluster['RestoreStatus'][name] = value.to_f

            when 'ClusterSecurityGroups'
              @in_cluster_security_groups = false
            when 'VpcSecurityGroups'
              @in_vpc_security_groups = false
            when 'PendingModifiedValues'
              @in_pending_modified_values = false

            when 'ClusterParameterGroup'
              @cluster['ClusterParameterGroups'] << {name => @cluster_parameter_group}
              @cluster_parameter_group = {}
            when 'ClusterSecurityGroup'
              @cluster['ClusterSecurityGroups'] << {name => @cluster_security_group}
              @cluster_security_group = {}
            when 'VpcSecurityGroup'
              @cluster['VpcSecurityGroups'] << {name => @vpc_security_group}
              @vpc_security_group = {}
            end
          end
        end
      end
    end
  end
end
