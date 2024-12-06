module Fog
  module Parsers
    module AWS
      module Elasticache
        # Base parser for ResponseMetadata, RequestId
        class Base < Fog::Parsers::Base
          def reset
            super
            @response = { 'ResponseMetadata' => {} }
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
