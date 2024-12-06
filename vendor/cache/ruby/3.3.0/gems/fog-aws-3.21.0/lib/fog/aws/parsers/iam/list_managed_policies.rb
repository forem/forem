require 'fog/aws/parsers/iam/policy_parser'

module Fog
  module Parsers
    module AWS
      module IAM
        class ListManagedPolicies < Fog::Parsers::AWS::IAM::PolicyParser
          def reset
            super
            @response = { 'Policies' => [] , 'Marker' => '', 'IsTruncated' => false}
          end

          def finished_policy(policy)
            @response['Policies'] << policy
          end

          def start_element(name,attrs = [])
            case name
            when 'AttachedPolicies'
              @stack << name
            when 'AttachedPolicy'
              @policy = fresh_policy
            when 'member'
              if @stack.last == 'AttachedPolicies'
                @policy = fresh_policy
              end
            end
            super
          end

          def end_element(name)
            case name
            when 'RequestId', 'Marker'
              @response[name] = value
            when 'IsTruncated'
              @response[name] = (value == 'true')
            when 'PolicyArn', 'PolicyName'
              @policy[name] = value
            when 'AttachedPolicies'
              if @stack.last == 'AttachedPolicies'
                @stack.pop
              end
            when 'member'
              if @stack.last == 'AttachedPolicies'
                finished_policy(@policy)
                @policy = nil
              end
            end
            super
          end
        end
      end
    end
  end
end
