require 'fog/aws/models/compute/volume'

module Fog
  module AWS
    class Compute
      class Volumes < Fog::Collection
        attribute :filters
        attribute :server

        model Fog::AWS::Compute::Volume

        # Used to create a volume.  There are 3 arguments and availability_zone and size are required.  You can generate a new key_pair as follows:
        # AWS.volumes.create(:availability_zone => 'us-east-1a', :size => 10)
        #
        # ==== Returns
        #
        #<Fog::AWS::Compute::Volume
        #  id="vol-1e2028b9",
        #  attached_at=nil,
        #  availability_zone="us-east-1a",
        #  created_at=Tue Nov 23 23:30:29 -0500 2010,
        #  delete_on_termination=nil,
        #  device=nil,
        #  server_id=nil,
        #  size=10,
        #  snapshot_id=nil,
        #  state="creating",
        #  tags=nil
        #>
        #
        # The volume can be retrieved by running AWS.volumes.get("vol-1e2028b9").  See get method below.
        #

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # Used to return all volumes.
        # AWS.volumes.all
        #
        # ==== Returns
        #
        #>>AWS.volumes.all
        #<Fog::AWS::Compute::Volume
        #  id="vol-1e2028b9",
        #  attached_at=nil,
        #  availability_zone="us-east-1a",
        #  created_at=Tue Nov 23 23:30:29 -0500 2010,
        #  delete_on_termination=nil,
        #  device=nil,
        #  server_id=nil,
        #  size=10,
        #  snapshot_id=nil,
        #  state="creating",
        #  tags=nil
        #>
        #
        # The volume can be retrieved by running AWS.volumes.get("vol-1e2028b9").  See get method below.
        #

        def all(filters_arg = filters)
          unless filters_arg.is_a?(Hash)
            Fog::Logger.deprecation("all with #{filters_arg.class} param is deprecated, use all('volume-id' => []) instead [light_black](#{caller.first})[/]")
            filters_arg = {'volume-id' => [*filters_arg]}
          end
          filters = filters_arg
          data = service.describe_volumes(filters).body
          load(data['volumeSet'])
          if server
            self.replace(self.select {|volume| volume.server_id == server.id})
          end
          self
        end

        # Used to retrieve a volume
        # volume_id is required to get the associated volume information.
        #
        # You can run the following command to get the details:
        # AWS.volumes.get("vol-1e2028b9")
        #
        # ==== Returns
        #
        #>> AWS.volumes.get("vol-1e2028b9")
        # <Fog::AWS::Compute::Volume
        #    id="vol-1e2028b9",
        #    attached_at=nil,
        #    availability_zone="us-east-1a",
        #    created_at=Tue Nov 23 23:30:29 -0500 2010,
        #    delete_on_termination=nil,
        #    device=nil,
        #    server_id=nil,
        #    size=10,
        #    snapshot_id=nil,
        #    state="available",
        #    tags={}
        #  >
        #

        def get(volume_id)
          if volume_id
            self.class.new(:service => service).all('volume-id' => volume_id).first
          end
        end

        def new(attributes = {})
          if server
            super({ :server => server }.merge!(attributes))
          else
            super
          end
        end
      end
    end
  end
end
