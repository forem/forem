module Fog
  module Parsers
    module AWS
      module STS
        class AssumeRole < Fog::Parsers::Base
          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'SessionToken', 'SecretAccessKey', 'Expiration', 'AccessKeyId'
              @response[name] = @value.strip
            when 'Arn', 'AssumedRoleId'
              @response[name] = @value.strip
            when 'PackedPolicySize'
              @response[name] = @value
            when 'RequestId'
              @response[name] = @value
            end
          end
        end
      end
    end
  end
end
