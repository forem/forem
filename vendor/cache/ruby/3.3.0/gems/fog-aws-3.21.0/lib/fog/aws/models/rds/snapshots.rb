require 'fog/aws/models/rds/snapshot'

module Fog
  module AWS
    class RDS
      class Snapshots < Fog::Collection
        attribute :server
        attribute :filters
        model Fog::AWS::RDS::Snapshot

        def initialize(attributes)
          self.filters ||= {}
          if attributes[:server]
            filters[:identifier] = attributes[:server].id
          end
          if attributes[:type]
            filters[:type] = attributes[:type]
          end
          super
        end

        # This method does NOT return all snapshots. Its implementation deliberately returns a single page
        # of results for any one call. It will return a single page based on the current or provided filters,
        # updating the filters with the marker for the next page. Calling this repeatedly will iterate
        # through pages. See the implementation of each for an example of such iteration.
        #
        # It is arguably incorrect for the method not to return all snapshots, particularly considering the
        # implementation in the corresponding 'elb' files. But this implementation has been released, and
        # backwards-compatibility requires leaving it as implemented.
        def all(filters_arg = filters)
          filters.merge!(filters_arg)

          page = service.describe_db_snapshots(filters).body['DescribeDBSnapshotsResult']
          filters[:marker] = page['Marker']
          load(page['DBSnapshots'])
        end

        # This will execute a block for each snapshot, fetching new pages of snapshots as required.
        def each(filters_arg = filters)
          if block_given?
            begin
              page = self.all(filters_arg)
              # We need to explicitly use the base 'each' method here on the page, otherwise we get infinite recursion
              base_each = Fog::Collection.instance_method(:each)
              base_each.bind(page).call { |snapshot| yield snapshot }
            end while self.filters[:marker]
          end
          self
        end

        def get(identity)
          data = service.describe_db_snapshots(:snapshot_id => identity).body['DescribeDBSnapshotsResult']['DBSnapshots'].first
          new(data) # data is an attribute hash
        rescue Fog::AWS::RDS::NotFound
          nil
        end

        def new(attributes = {})
          if server
            super({ :instance_id => server.id }.merge!(attributes))
          else
            super
          end
        end
      end
    end
  end
end
