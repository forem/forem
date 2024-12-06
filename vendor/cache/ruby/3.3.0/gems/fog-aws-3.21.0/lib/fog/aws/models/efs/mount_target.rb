module Fog
  module AWS
    class EFS
      class MountTarget < Fog::Model
        identity :id, :aliases => "MountTargetId"

        attribute :file_system_id,       :aliases => "FileSystemId"
        attribute :ip_address,           :aliases => "IpAddress"
        attribute :state,                :aliases => "LifeCycleState"
        attribute :network_interface_id, :aliases => "NetworkInterfaceId"
        attribute :owner_id,             :aliases => "OwnerId"
        attribute :subnet_id,            :aliases => "SubnetId"

        def ready?
          state == 'available'
        end

        def destroy
          requires :identity
          service.delete_mount_target(self.identity)
          true
        end

        def file_system
          requires :file_system_id
          service.file_systems.get(self.file_system_id)
        end

        def security_groups
          if persisted?
            requires :identity
            service.describe_mount_target_security_groups(self.identity).body["SecurityGroups"]
          else
            @security_groups || []
          end
        end

        def security_groups=(security_groups)
          if persisted?
            requires :identity
            service.modify_mount_target_security_groups(self.identity, security_groups)
          else
            @security_groups = security_groups
          end
          security_groups
        end

        def save
          requires :file_system_id, :subnet_id
          params = {}
          params.merge!('IpAddress' => self.ip_address) if self.ip_address
          params.merge!('SecurityGroups' => @security_groups) if @security_groups

          merge_attributes(service.create_mount_target(self.file_system_id, self.subnet_id, params).body)
        end
      end
    end
  end
end
