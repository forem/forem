module Fog
  module Parsers
    module AWS
      module RDS
        class SnapshotParser < Fog::Parsers::Base
          def reset
            @db_snapshot = fresh_snapshot
          end

          def fresh_snapshot
            {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'AllocatedStorage', 'Port'
              @db_snapshot[name] = value.to_i
            when 'InstanceCreateTime', 'SnapshotCreateTime'
              @db_snapshot[name] = Time.parse(value)
            else
              @db_snapshot[name] = value
            end
          end
        end
      end
    end
  end
end
