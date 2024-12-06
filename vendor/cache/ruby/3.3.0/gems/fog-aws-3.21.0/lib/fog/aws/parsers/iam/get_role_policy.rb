module Fog
  module Parsers
    module AWS
      module IAM
        class GetRolePolicy < Fog::Parsers::Base
          def reset
            @response = {'Policy' => {}}
          end

          def end_element(name)
            case name
            when 'RoleName', 'PolicyName'
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
