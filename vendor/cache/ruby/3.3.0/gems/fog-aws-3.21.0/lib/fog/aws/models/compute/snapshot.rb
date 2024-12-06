module Fog
  module AWS
    class Compute
      class Snapshot < Fog::Model
        identity  :id,          :aliases => 'snapshotId'

        attribute :description
        attribute :encrypted
        attribute :progress
        attribute :created_at,     :aliases => 'startTime'
        attribute :owner_id,       :aliases => 'ownerId'
        attribute :state,          :aliases => 'status'
        attribute :tags,           :aliases => 'tagSet'
        attribute :volume_id,      :aliases => 'volumeId'
        attribute :volume_size,    :aliases => 'volumeSize'
        attribute :status_message, :aliases => 'statusMessage'

        def destroy
          requires :id

          service.delete_snapshot(id)
          true
        end

        def ready?
          state == 'completed'
        end

        def save
          raise Fog::Errors::Error.new('Resaving an existing object may create a duplicate') if persisted?
          requires :volume_id

          data = service.create_snapshot(volume_id, description).body
          new_attributes = data.reject {|key,value| key == 'requestId'}
          merge_attributes(new_attributes)
          true
        end

        def volume
          requires :id
          service.describe_volumes(volume_id)
        end

        private

        def volume=(new_volume)
          self.volume_id = new_volume.volume_id
        end
      end
    end
  end
end
