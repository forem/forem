module Fog
  module Parsers
    module AWS
      module STS
        class AssumeRoleWithWebIdentity < Fog::Parsers::Base
          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'AssumedRoleUser', 'Audience', 'Credentials', 'PackedPolicySize', 'Provider', 'SubjectFromWebIdentityToken'
              @response[name] = @value.strip
            end
          end
        end
      end
    end
  end
end
