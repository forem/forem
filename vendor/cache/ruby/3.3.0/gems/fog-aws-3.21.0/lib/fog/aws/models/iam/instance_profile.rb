module Fog
  module AWS
    class IAM
      class InstanceProfile < Fog::Model
        identity :name, :aliases => 'InstanceProfileName'

        attribute :id,          :aliases => 'InstanceProfileId'
        attribute :roles,       :aliases => 'Roles',              :type => :array
        attribute :arn,         :aliases => 'Arn'
        attribute :path,        :aliases => 'Path'
        attribute :create_date, :aliases => 'CreateDate',         :type => :time

        def add_role(role_name)
          requires :identity
          service.add_role_to_instance_profile(role_name, self.name)
          true
        end

        def remove_role(role_name)
          requires :identity
          service.remove_role_from_instance_profile(role_name, self.name)
          true
        end

        def destroy
          requires :identity
          service.delete_instance_profile(self.identity)
          true
        end

        def save
          requires :identity

          data = service.create_instance_profile(self.name, self.path).body['InstanceProfile']
          merge_attributes(data)
        end
      end
    end
  end
end
