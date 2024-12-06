module Fog
  module Parsers
    module AWS
      module Compute
        class CreateImage < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'instanceId', 'requestId', 'name', 'description', 'noReboot', 'imageId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
