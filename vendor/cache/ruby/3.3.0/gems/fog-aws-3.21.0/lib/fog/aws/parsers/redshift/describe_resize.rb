module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeResize < Fog::Parsers::Base
          # :target_node_type - (String)
          # :target_number_of_nodes - (Integer)
          # :target_cluster_type - (String)
          # :status - (String)
          # :import_tables_completed - (Array)
          # :import_tables_in_progress - (Array)
          # :import_tables_not_started - (Array)
          def reset
            @response = { 'ImportTablesCompleted' => [], 'ImportTablesInProgress' => [], 'ImportTablesNotStarted' => []}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ImportTablesCompleted'
              @in_import_tables_completed = true
            when 'ImportTablesInProgress'
              @in_import_tables_in_progress = true
            when 'ImportTablesNotStarted'
              @in_import_tables_not_started = true
            end
          end

          def end_element(name)
            super
            case name
            when 'TargetNodeType', 'TargetClusterType', 'Status'
              @response[name] = value
            when 'TargetNumberOfNodes'
              @response[name] = value.to_i
            when 'ImportTablesCompleted'
              @in_import_tables_completed = false
            when 'ImportTablesInProgress'
              @in_import_tables_in_progress = false
            when 'ImportTablesNotStarted'
              @in_import_tables_not_started = false
            when 'member'
              if @in_import_tables_completed
                @response['ImportTablesCompleted'] << value
              end
              if @in_import_tables_not_started
                @response['ImportTablesNotStarted'] << value
              end
              if @in_import_tables_in_progress
                @response['ImportTablesInProgress'] << value
              end
            end
          end
        end
      end
    end
  end
end
