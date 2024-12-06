module Fog
  module Parsers
    module AWS
      module IAM
        class GetUserPolicy < Fog::Parsers::Base
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_GetUserPolicy.html

          def reset
            @response = { 'Policy' => {} }
          end

          def end_element(name)
            case name
            when 'UserName', 'PolicyName'
              @response['Policy'][name] = value
            when 'PolicyDocument'
              @response['Policy'][name] = if decoded_string = URI.decode_www_form_component(value)
                                  Fog::JSON.decode(decoded_string) rescue value
                                else
                                  value
                                end
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
