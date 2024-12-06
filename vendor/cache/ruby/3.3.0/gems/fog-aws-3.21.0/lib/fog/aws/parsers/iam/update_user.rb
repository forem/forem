module Fog
  module Parsers
    module AWS
      module IAM
        class UpdateUser < Fog::Parsers::Base
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_UpdateUser.html

          def reset
            @response = { 'User' => {} }
          end

          def end_element(name)
            case name
            when 'Arn', 'UserId', 'UserName', 'Path'
              @response['User'][name] = value
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
