module Fog
  module Parsers
    module AWS
      module IAM
        class GetUser < Fog::Parsers::Base
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetUser.html

          def reset
            @response = { 'User' => {} }
          end

          def end_element(name)
            case name
            when 'Arn', 'UserId', 'UserName', 'Path'
              @response['User'][name] = value
            when 'CreateDate'
              @response['User'][name] = Time.parse(value)
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
