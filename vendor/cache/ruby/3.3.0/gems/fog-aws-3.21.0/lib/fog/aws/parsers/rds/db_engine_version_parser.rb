module Fog
  module Parsers
    module AWS
      module RDS
        class DBEngineVersionParser < Fog::Parsers::Base
          def reset
            @db_engine_version = fresh_engine_version
          end

          def fresh_engine_version
            {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBEngineDescription' then @db_engine_version['DBEngineDescription'] = @value
            when 'DBEngineVersionDescription' then @db_engine_version['DBEngineVersionDescription'] = @value
            when 'DBParameterGroupFamily' then @db_engine_version['DBParameterGroupFamily'] = @value
            when 'DBEngineVersionIdentifier' then @db_engine_version['DBEngineVersionIdentifier'] = @value
            when 'Engine' then @db_engine_version['Engine'] = @value
            when 'EngineVersion' then @db_engine_version['EngineVersion'] = @value
            end
          end
        end
      end
    end
  end
end
