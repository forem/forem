require 'fog/aws/models/efs/mount_target'

module Fog
  module AWS
    class EFS
      class MountTargets < Fog::Collection
        attribute :file_system_id

        model Fog::AWS::EFS::MountTarget

        def all
          data = service.describe_mount_targets(:file_system_id => self.file_system_id).body["MountTargets"]
          load(data)
        end

        def get(identity)
          data = service.describe_mount_targets(:id => identity).body["MountTargets"].first
          new(data)
        rescue Fog::AWS::EFS::NotFound
          nil
        end
      end
    end
  end
end
