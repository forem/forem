module Fog
  module AWS
    class IAM
      class Role < Fog::Model

        identity  :id, :aliases => 'RoleId'
        attribute :rolename, :aliases => 'RoleName'
        attribute :create_date, :aliases => 'CreateDate', :type => :time
        attribute :assume_role_policy_document, :aliases => 'AssumeRolePolicyDocument'
        attribute :arn, :aliases => 'Arn'
        attribute :path, :aliases => 'Path'

        def save
          raise Fog::Errors::Error.new('Resaving an existing object may create a duplicate') if persisted?
          requires :rolename
          requires :assume_role_policy_document

          data = service.create_role(rolename, assume_role_policy_document, path).body["Role"]
          merge_attributes(data)
          true
        end

        def attach(policy_or_arn)
          requires :rolename

          arn = if policy_or_arn.respond_to?(:arn)
                  policy_or_arn.arn
                else
                  policy_or_arn
                end

          service.attach_role_policy(self.rolename, arn)
        end

        def detach(policy_or_arn)
          requires :rolename

          arn = if policy_or_arn.respond_to?(:arn)
                  policy_or_arn.arn
                else
                  policy_or_arn
                end

          service.detach_role_policy(self.rolename, arn)
        end

        def attached_policies
          requires :rolename

          service.managed_policies(:role_name => self.rolename)
        end

        def instance_profiles
          requires :rolename
          service.instance_profiles.load(service.list_instance_profiles_for_role(self.rolename).body["InstanceProfiles"])
        end

        def destroy
          requires :rolename

          service.delete_role(rolename)
          true
        end
      end
    end
  end
end
