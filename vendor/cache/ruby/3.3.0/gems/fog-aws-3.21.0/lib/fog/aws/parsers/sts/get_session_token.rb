module Fog
  module Parsers
    module AWS
      module STS
        class GetSessionToken < Fog::Parsers::Base
					# http://docs.amazonwebservices.com/IAM/latest/UserGuide/index.html?CreatingFedTokens.html

          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'SessionToken', 'SecretAccessKey', 'Expiration', 'AccessKeyId'
              @response[name] = @value.strip
            when 'Arn', 'FederatedUserId', 'PackedPolicySize'
              @response[name] = @value.strip
            when 'RequestId'
              @response[name] = @value
            end
          end
        end
      end
    end
  end
end
