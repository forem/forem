require 'fog/aws/models/compute/dhcp_option'

module Fog
  module AWS
    class Compute
      class DhcpOptions < Fog::Collection
        attribute :filters

        model Fog::AWS::Compute::DhcpOption

        # Creates a new dhcp option
        #
        # AWS.dhcp_options.new
        #
        # ==== Returns
        #
        # Returns the details of the new DHCP options
        #
        #>> AWS.dhcp_options.new
        #=>   <Fog::AWS::Compute::DhcpOption
        #id=nil,
        #dhcp_configuration_set=nil,
        #tag_set=nil
        #>
        #

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # Returns an array of all DhcpOptions that have been created
        #
        # AWS.dhcp_options.all
        #
        # ==== Returns
        #
        # Returns an array of all DhcpOptions
        #
        #>> AWS.dhcp_options.all
        #<Fog::AWS::Compute::DhcpOptions
        #filters={}
        #[
        #<Fog::AWS::Compute::DhcpOption
        #id="dopt-some-id",
        #dhcp_configuration_set={"vpcId"=>"vpc-some-id", "state"=>"available"},
        #tag_set={}
        #>
        #]
        #>
        #

        def all(filters_arg = filters)
          unless filters_arg.is_a?(Hash)
            Fog::Logger.warning("all with #{filters_arg.class} param is deprecated, use all('internet-gateway-id' => []) instead [light_black](#{caller.first})[/]")
            filters_arg = {'dhcp-options-id' => [*filters_arg]}
          end
          filters = filters_arg
          data = service.describe_dhcp_options(filters).body
          load(data['dhcpOptionsSet'])
        end

        # Used to retrieve an DhcpOption
        #
        # You can run the following command to get the details:
        # AWS.dhcp_options.get("dopt-12345678")
        #
        # ==== Returns
        #
        #>> AWS.dhcp_options.get("dopt-12345678")
        #=>   <Fog::AWS::Compute::DhcpOption
        #id="dopt-12345678",
        #dhcp_configuration_set={"vpcId"=>"vpc-12345678", "state"=>"available"},
        #tag_set={}
        #>
        #

        def get(dhcp_options_id)
          if dhcp_options_id
            self.class.new(:service => service).all('dhcp-options-id' => dhcp_options_id).first
          end
        end
      end
    end
  end
end
