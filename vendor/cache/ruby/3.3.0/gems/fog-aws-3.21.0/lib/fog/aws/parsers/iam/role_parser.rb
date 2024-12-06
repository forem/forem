module Fog
  module Parsers
    module AWS
      module IAM
        class RoleParser < Fog::Parsers::Base
          def reset
            @role = {}
            @stack = []
          end

          def start_element(name,attrs = [])
            case name
            when 'Roles'
              @stack << name
            when 'Role'
              @role = {}
            when 'member'
              if @stack.last == 'Roles'
                @role = {}
              end
            end
            super
          end

          def end_element(name)
            case name
            when 'Arn', 'AssumeRolePolicyDocument', 'Path', 'RoleId','RoleName'
              @role[name] = value if @role
            when 'CreateDate'
              @role[name] = Time.parse(value) if @role
            when 'Role'
              finished_role(@role)
              @role = nil
            when 'Roles'
              if @stack.last == 'Roles'
                @stack.pop
              end
            when 'member'
              if @stack.last == 'Roles'
                finished_role(@role)
                @role = nil
              end
            end
          end
        end
      end
    end
  end
end
