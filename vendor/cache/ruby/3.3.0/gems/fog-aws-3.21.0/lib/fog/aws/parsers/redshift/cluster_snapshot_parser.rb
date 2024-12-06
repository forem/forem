module Fog
  module Parsers
    module Redshift
      module AWS
        class ClusterSnapshotParser < Fog::Parsers::Base
          # :snapshot_identifier - (String)
          # :cluster_identifier - (String)
          # :snapshot_create_time - (Time)
          # :status - (String)
          # :port - (Integer)
          # :availability_zone - (String)
          # :cluster_create_time - (Time)
          # :master_username - (String)
          # :cluster_version - (String)
          # :snapshot_type - (String)
          # :node_type - (String)
          # :number_of_nodes - (Integer)
          # :db_name - (String)
          # :vpc_id - (String)
          # :encrypted - (Boolean)
          # :accounts_with_restore_access - (Array)
          #   :account_id - (String)
          # :owner_account - (String)
          # :total_backup_size_in_mega_bytes - (Numeric)
          # :actual_incremental_backup_size_in_mega_bytes - (Numeric)
          # :backup_progress_in_mega_bytes - (Numeric)
          # :current_backup_rate_in_mega_bytes_per_second - (Numeric)
          # :estimated_seconds_to_completion - (Integer)
          # :elapsed_time_in_seconds - (Integer)

          def reset
            @snapshot = fresh_snapshot
          end

          def fresh_snapshot
            {'Snapshot' =>  { 'AccountsWithRestoreAccess' => [] }}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            super
            case name
            when 'SnapshotIdentifier', 'ClusterIdentifier', 'Status', 'AvailabilityZone', 'MasterUsername', 'ClusterVersion', 'SnapshotType', 'NodeType',
              'DBName', 'VpcId', 'OwnerAccount'
              @snapshot['Snapshot'][name] = value
            when 'Port', 'NumberOfNodes', 'ElapsedTimeInSeconds', 'EstimatedSecondsToCompletion'
              @snapshot['Snapshot'][name] = value.to_i
            when 'SnapshotCreateTime', 'ClusterCreateTime'
              @snapshot['Snapshot'][name] = Time.parse(value)
            when 'Encrypted'
              @snapshot['Snapshot'][name] = (value == "true")
            when 'TotalBackupSizeInMegaBytes', 'ActualIncrementalBackupSizeInMegaBytes', 'BackupProgressInMegaBytes', 'CurrentBackupRateInMegaBytesPerSecond'
              @snapshot['Snapshot'][name] = value.to_f
            when 'AccountId'
              @snapshot['Snapshot']['AccountsWithRestoreAccess'] << value
            end
          end
        end
      end
    end
  end
end
