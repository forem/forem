require 'fog/aws/models/compute/internet_gateway'

module Fog
  module AWS
    class Compute
      class InternetGateways < Fog::Collection
        attribute :filters

        model Fog::AWS::Compute::InternetGateway

        # Creates a new internet gateway
        #
        # AWS.internet_gateways.new
        #
        # ==== Returns
        #
        # Returns the details of the new InternetGateway
        #
        #>> AWS.internet_gateways.new
        #=>   <Fog::AWS::Compute::InternetGateway
        #id=nil,
        #attachment_set=nil,
        #tag_set=nil
        #>
        #

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # Returns an array of all InternetGateways that have been created
        #
        # AWS.internet_gateways.all
        #
        # ==== Returns
        #
        # Returns an array of all InternetGateways
        #
        #>> AWS.internet_gateways.all
        #<Fog::AWS::Compute::InternetGateways
        #filters={}
        #[
        #<Fog::AWS::Compute::InternetGateway
        #id="igw-some-id",
        #attachment_set={"vpcId"=>"vpc-some-id", "state"=>"available"},
        #tag_set={}
        #>
        #]
        #>
        #

        def all(filters_arg = filters)
          unless filters_arg.is_a?(Hash)
            Fog::Logger.warning("all with #{filters_arg.class} param is deprecated, use all('internet-gateway-id' => []) instead [light_black](#{caller.first})[/]")
            filters_arg = {'internet-gateway-id' => [*filters_arg]}
          end
          filters = filters_arg
          data = service.describe_internet_gateways(filters).body
          load(data['internetGatewaySet'])
        end

        # Used to retrieve an InternetGateway
        #
        # You can run the following command to get the details:
        # AWS.internet_gateways.get("igw-12345678")
        #
        # ==== Returns
        #
        #>> AWS.internet_gateways.get("igw-12345678")
        #=>   <Fog::AWS::Compute::InternetGateway
        #id="igw-12345678",
        #attachment_set={"vpcId"=>"vpc-12345678", "state"=>"available"},
        #tag_set={}
        #>
        #

        def get(internet_gateway_id)
          if internet_gateway_id
            self.class.new(:service => service).all('internet-gateway-id' => internet_gateway_id).first
          end
        end
      end
    end
  end
end
