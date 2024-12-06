module Fog
  module Parsers
    module AWS
      module Compute
        class RegisterImage < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'requestId', 'imageId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
