module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeKeyPairs < Fog::Parsers::Base
          def reset
            @key = {}
            @response = { 'keySet' => [] }
          end

          def end_element(name)
            case name
            when 'item'
              @response['keySet'] << @key
              @key = {}
            when 'keyFingerprint', 'keyName'
              @key[name] = value
            when 'requestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
