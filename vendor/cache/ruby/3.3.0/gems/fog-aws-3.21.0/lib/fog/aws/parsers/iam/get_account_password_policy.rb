module Fog
  module Parsers
    module AWS
      module IAM
        class GetAccountPolicyPolicy < Fog::Parsers::Base
          def reset
            @response = {'AccountPasswordPolicy' => {}}
          end

          def end_element(name)
            case name
            when 'MinimumPasswordLength', 'MaxPasswordAge','PasswordReusePrevention'
              #boolean values
              @response['AccountPasswordPolicy'][name] = !!value
            when 'RequireSymbols','RequireNumbers','RequireUppercaseCharacters','RequireLowercaseCharacters','AllowUsersToChangePassword','HardExpiry','ExpirePasswords'
              #integer values              
              @response['AccountPasswordPolicy'][name] = value.to_i
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
