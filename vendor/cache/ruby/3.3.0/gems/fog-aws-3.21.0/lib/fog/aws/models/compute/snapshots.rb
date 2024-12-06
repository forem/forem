require 'fog/aws/models/compute/snapshot'

module Fog
  module AWS
    class Compute
      class Snapshots < Fog::Collection
        attribute :filters
        attribute :volume

        model Fog::AWS::Compute::Snapshot

        def initialize(attributes)
          self.filters ||= { 'RestorableBy' => 'self' }
          super
        end

        def all(filters_arg = filters, options = {})
          unless filters_arg.is_a?(Hash)
            Fog::Logger.deprecation("all with #{filters_arg.class} param is deprecated, use all('snapshot-id' => []) instead [light_black](#{caller.first})[/]")
            filters_arg = {'snapshot-id' => [*filters_arg]}
          end
          filters = filters_arg
          data = service.describe_snapshots(filters.merge!(options)).body
          load(data['snapshotSet'])
          if volume
            self.replace(self.select {|snapshot| snapshot.volume_id == volume.id})
          end
          self
        end

        def get(snapshot_id)
          if snapshot_id
            self.class.new(:service => service).all('snapshot-id' => snapshot_id).first
          end
        end

        def new(attributes = {})
          if volume
            super({ 'volumeId' => volume.id }.merge!(attributes))
          else
            super
          end
        end
      end
    end
  end
end
