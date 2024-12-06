module Fog
  module Parsers
    module AWS
      module IAM
        class ListAccountAliases < Fog::Parsers::Base
          def reset
            @response = { 'AccountAliases' => [] }
          end

          def end_element(name)
            case name
            when 'member'
              @response['AccountAliases'] << @value
            when 'IsTruncated'
              response[name] = (@value == 'true')
            when 'Marker', 'RequestId'
              response[name] = @value
            end
          end
        end
      end
    end
  end
end
