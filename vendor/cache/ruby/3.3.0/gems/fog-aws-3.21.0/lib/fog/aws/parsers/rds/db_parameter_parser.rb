module Fog
  module Parsers
    module AWS
      module RDS
        class DBParameterParser < Fog::Parsers::Base
          def reset
            @db_parameter = new_db_parameter
          end

          def new_db_parameter
            {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'IsModifiable'
              @value == "true" ? true : false
            else
              @db_parameter[name] = @value.strip
            end
          end
        end
      end
    end
  end
end
