module Fog
  module AWS
    class Compute
      class RouteTable < Fog::Model
        identity :id,                :aliases => 'routeTableId'

        attribute :vpc_id,           :aliases => 'vpcId'
        attribute :routes,           :aliases => 'routeSet'
        attribute :associations,     :aliases => 'associationSet'
        attribute :tags,             :aliases => 'tagSet'


        def initialize(attributes={})
          super
        end

        # Remove an existing route table
        #
        # route_tables.destroy
        #
        # ==== Returns
        #
        # True or false depending on the result
        #

        def destroy
          requires :id

          service.delete_route_table(id)
          true
        end

        # Create a route table
        #
        # >> routetable = connection.route_tables.new
        # >> routetable.save
        #
        # == Returns:
        #
        # True or an exception depending on the result. Keep in mind that this *creates* a new route table.
        #

        def save
          requires :vpc_id

          data = service.create_route_table(vpc_id).body['routeTable'].first
          new_attributes = data.reject {|key,value| key == 'requestId'}
          merge_attributes(new_attributes)
          true
        end

        private

        def associationSet=(new_association_set)
          merge_attributes(new_association_set.first || {})
        end

        def routeSet=(new_route_set)
          merge_attributes(new_route_set || {})
        end
      end
    end
  end
end
