module Fog
  module Parsers
    module AWS
      module IAM
        class ListAccessKeys < Fog::Parsers::Base
          def reset
            @access_key = {}
            @response = { 'AccessKeys' => [] }
          end

          def end_element(name)
            case name
            when 'AccessKeyId', 'Status', 'UserName'
              @access_key[name] = value
            when 'member'
              @response['AccessKeys'] << @access_key
              @access_key = {}
            when 'IsTruncated'
              response[name] = (value == 'true')
            when 'Marker', 'RequestId'
              response[name] = value
            end
          end
        end
      end
    end
  end
end
