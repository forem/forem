module Fog
  module AWS
    class Compute
      class Volume < Fog::Model
        identity  :id,                    :aliases => 'volumeId'

        attribute :attached_at,           :aliases => 'attachTime'
        attribute :availability_zone,     :aliases => 'availabilityZone'
        attribute :created_at,            :aliases => 'createTime'
        attribute :delete_on_termination, :aliases => 'deleteOnTermination'
        attribute :device
        attribute :encrypted
        attribute :key_id,                :aliases => ['KmsKeyId', 'kmsKeyId']
        attribute :iops
        attribute :server_id,             :aliases => 'instanceId'
        attribute :size
        attribute :snapshot_id,           :aliases => 'snapshotId'
        attribute :state,                 :aliases => 'status'
        attribute :tags,                  :aliases => 'tagSet'
        attribute :type,                  :aliases => 'volumeType'

        def initialize(attributes = {})
          # assign server first to prevent race condition with persisted?
          @server = attributes.delete(:server)
          super
        end

        def destroy
          requires :id

          service.delete_volume(id)
          true
        end

        def ready?
          state == 'available'
        end

        def modification_in_progress?
          modifications.any? { |m| m['modificationState'] != 'completed' }
        end

        def modifications
          requires :identity
          service.describe_volumes_modifications('volume-id' => self.identity).body['volumeModificationSet']
        end

        def save
          if identity
            update_params = {
              'Size'       => self.size,
              'Iops'       => self.iops,
              'VolumeType' => self.type
            }

            service.modify_volume(self.identity, update_params)
            true
          else
            requires :availability_zone
            requires_one :size, :snapshot_id

            requires :iops if type == 'io1'

            data = service.create_volume(availability_zone, size, create_params).body
            merge_attributes(data)

            if tags = self.tags
              # expect eventual consistency
              Fog.wait_for { service.volumes.get(identity) }
              service.create_tags(identity, tags)
            end

            attach(@server, device) if @server && device
          end

          true
        end

        def server
          requires :server_id
          service.servers.get(server_id)
        end

        def snapshots
          requires :id
          service.snapshots(:volume => self)
        end

        def snapshot(description)
          requires :id
          service.create_snapshot(id, description)
        end

        def force_detach
          detach(true)
        end

        def attach(new_server, new_device)
          if !persisted?
            @server = new_server
            self.availability_zone = new_server.availability_zone
          elsif new_server
            wait_for { ready? }
            @server = nil
            self.server_id = new_server.id
            service.attach_volume(server_id, id, new_device)
            reload
          end
        end

        def detach(force = false)
          @server = nil
          self.server_id = nil
          if persisted?
            service.detach_volume(id, 'Force' => force)
            reload
          end
        end

        def server=(_)
          raise NoMethodError, 'use Fog::AWS::Compute::Volume#attach(server, device)'
        end

        private

        def attachmentSet=(new_attachment_set)
          merge_attributes(new_attachment_set.first || {})
        end

        def create_params
          {
            'Encrypted'  => encrypted,
            'KmsKeyId'   => key_id,
            'Iops'       => iops,
            'SnapshotId' => snapshot_id,
            'VolumeType' => type
          }
        end
      end
    end
  end
end
