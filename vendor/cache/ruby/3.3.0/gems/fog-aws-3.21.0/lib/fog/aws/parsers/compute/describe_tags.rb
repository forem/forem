module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeTags < Fog::Parsers::Base
          def reset
            @tag = {}
            @response = { 'tagSet' => [] }
          end

          def end_element(name)
            case name
            when 'resourceId', 'resourceType', 'key', 'value'
              @tag[name] = value
            when 'item'
              @response['tagSet'] << @tag
              @tag = {}
            when 'requestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
