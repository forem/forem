module Fog
  module Parsers
    module AWS
      module IAM
        class BaseInstanceProfile < Fog::Parsers::Base
          def reset
            super
            @stack = []
          end

          def start_element(name,attrs = [])
            super
            case name

            when 'InstanceProfile'
              @instance_profile = {'Roles' =>[]}
            when 'InstanceProfiles'
              @stack << 'InstanceProfiles'
            when 'Roles'
              @stack << 'Role'
            when 'member'
              case @stack.last
              when 'InstanceProfiles'
                @instance_profile = {'Roles' =>[]}
              when 'Roles'
                if @instance_profile
                  @role = {}
                end
              end
            end
          end

          def end_element(name)
            if @instance_profile
              case name
              when 'Arn', 'Path'
                if @role
                  @role[name] = value
                else
                  @instance_profile[name] = value
                end
              when 'AssumeRolePolicyDocument', 'RoleId','RoleName'
                @role[name] = value if @role
              when 'CreateDate'
                if @role
                  @role[name] = Time.parse(value)
                else
                  @instance_profile[name] = Time.parse(value)
                end
              when 'member'
                case @stack.last
                when 'InstanceProfiles'
                  finished_instance_profile(@instance_profile)
                  @instance_profile = nil
                when 'Roles'
                  if @instance_profile
                    @instance_profile['Roles'] << @role
                    @role = nil
                  end
                end
              when 'InstanceProfiles', 'Roles'
                @stack.pop
              when 'InstanceProfile'
                finished_instance_profile(@instance_profile)
                @instance_profile = nil
              when 'InstanceProfileName', 'InstanceProfileId'
                @instance_profile[name] = value
              end
            end
          end
        end
      end
    end
  end
end
