module Fog
  module Parsers
    module AWS
      module Compute
        class GetConsoleOutput < Fog::Parsers::Base
          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'instanceId', 'requestId'
              @response[name] = value
            when 'output'
              @response[name] = value && Base64.decode64(value)
            when 'timestamp'
              @response[name] = Time.parse(value)
            end
          end
        end
      end
    end
  end
end
