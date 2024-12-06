module Fog
  module Parsers
    module AWS
      module IAM
        class PolicyParser < Fog::Parsers::Base
          def reset
            @policy = fresh_policy
            @stack = []
          end

          def start_element(name,attrs = [])
            case name
            when 'Policies'
              @stack << name
            when 'Policy'
              @policy = fresh_policy
            when 'member'
              if @stack.last == 'Policies'
                @policy = fresh_policy
              end
            end
            super
          end

          def fresh_policy
            {'AttachmentCount' => 0, 'Description' => ''}
          end

          def end_element(name)
            case name
            when 'Arn', 'DefaultVersionId', 'Description', 'Path', 'PolicyName', 'PolicyId'
              @policy[name] = value
            when 'CreateDate', 'UpdateDate'
              @policy[name] = Time.parse(value)
            when 'IsAttachable'
              @policy[name] = (value == 'true')
            when 'AttachmentCount'
              @policy[name] = value.to_i
            when 'Policy'
              finished_policy(@policy)
              @policy = nil
            when 'Policies'
              if @stack.last == 'Policies'
                @stack.pop
              end
            when 'member'
              if @stack.last == 'Policies'
                finished_policy(@policy)
                @policy = nil
              end
            end
          end
        end
      end
    end
  end
end
