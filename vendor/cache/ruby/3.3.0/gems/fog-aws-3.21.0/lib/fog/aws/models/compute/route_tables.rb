require 'fog/aws/models/compute/route_table'

module Fog
  module AWS
    class Compute
      class RouteTables < Fog::Collection
        attribute :filters

        model Fog::AWS::Compute::RouteTable

        # Creates a new route table
        #
        # AWS.route_tables.new
        #
        # ==== Returns
        #
        # Returns the details of the new route table
        #
        #>> AWS.route_tables.new
        # <Fog::AWS::Compute::RouteTable
        # id=nil,
        # vpc_id=nil,
        # routes=nil,
        # associations=nil,
        # tags=nil
        # >
        #

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # Returns an array of all route tables that have been created
        #
        # AWS.route_tables.all
        #
        # ==== Returns
        #
        # Returns an array of all route tables
        #
        #>> AWS.route_tables.all
        # <Fog::AWS::Compute::RouteTables
        # filters={}
        # [
        # <Fog::AWS::Compute::RouteTable
        # id="rtb-41e8552f",
        # TODO
        # >
        # ]
        # >
        #

        def all(filters_arg = filters)
          unless filters_arg.is_a?(Hash)
            Fog::Logger.warning("all with #{filters_arg.class} param is deprecated, use all('route-table-id' => []) instead [light_black](#{caller.first})[/]")
            filters_arg = {'route-table-id' => [*filters_arg]}
          end
          filters = filters_arg
          data = service.describe_route_tables(filters).body
          load(data['routeTableSet'])
        end

        # Used to retrieve a route table
        # route_table_id is required to get the associated route table information.
        #
        # You can run the following command to get the details:
        # AWS.route_tables.get("rtb-41e8552f")
        #
        # ==== Returns
        #
        #>> AWS.route_tables.get("rtb-41e8552f")
        # <Fog::AWS::Compute::RouteTable
        # id="rtb-41e8552f",
        # TODO
        # >
        #

        def get(route_table_id)
          if route_table_id
            self.class.new(:service => service).all('route-table-id' => route_table_id).first
          end
        end
      end
    end
  end
end
