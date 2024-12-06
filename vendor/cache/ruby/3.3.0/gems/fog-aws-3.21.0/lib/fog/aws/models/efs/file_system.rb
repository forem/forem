module Fog
  module AWS
    class EFS
      class FileSystem < Fog::Model
        identity :id, :aliases => 'FileSystemId'

        attribute :owner_id,                :aliases => 'OwnerId'
        attribute :creation_token,          :aliases => 'CreationToken'
        attribute :performance_mode,        :aliases => 'PerformanceMode'
        attribute :encrypted,               :aliases => 'Encrypted'
        attribute :kms_key_id,              :aliases => 'KmsKeyId'
        attribute :creation_time,           :aliases => 'CreationTime'
        attribute :state,                   :aliases => 'LifeCycleState'
        attribute :name,                    :aliases => 'Name'
        attribute :number_of_mount_targets, :aliases => 'NumberOfMountTargets'
        attribute :size_in_bytes,           :aliases => 'SizeInBytes'

        def ready?
          state == 'available'
        end

        def mount_targets
          requires :identity
          service.mount_targets(:file_system_id => self.identity).all
        end

        def destroy
          requires :identity

          service.delete_file_system(self.identity)

          true
        end

        def save
          params = {}
          params.merge!(:performance_mode => self.performance_mode) if self.performance_mode
          params.merge!(:encrypted        => self.encrypted)        if self.encrypted
          params.merge!(:kms_key_id       => self.kms_key_id)       if self.kms_key_id

          merge_attributes(service.create_file_system(self.creation_token || Fog::Mock.random_hex(32), params).body)
        end
      end
    end
  end
end
