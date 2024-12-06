module Fog
  module Parsers
    module AWS
      module IAM
        require 'fog/aws/parsers/iam/policy_parser'
        class SinglePolicy < Fog::Parsers::AWS::IAM::PolicyParser
          def reset
            super
            @response = { 'Policy' => {} }
          end

          def finished_policy(policy)
            @response['Policy'] = policy
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response[name] = value
            end
            super
          end
        end
      end
    end
  end
end
