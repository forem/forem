require 'fog/aws/models/compute/network_interface'

module Fog
  module AWS
    class Compute
      class NetworkInterfaces < Fog::Collection
        attribute :filters

        model Fog::AWS::Compute::NetworkInterface

        # Creates a new network interface
        #
        # AWS.network_interfaces.new
        #
        # ==== Returns
        #
        # Returns the details of the new network interface
        #
        #>> AWS.network_interfaces.new
        #  <Fog::AWS::Compute::NetworkInterface
        #    network_interface_id=nil
        #    state=nil
        #    request_id=nil
        #    network_interface_id=nil
        #    subnet_id=nil
        #    vpc_id=nil
        #    availability_zone=nil
        #    description=nil
        #    owner_id=nil
        #    requester_id=nil
        #    requester_managed=nil
        #    status=nil
        #    mac_address=nil
        #    private_ip_address=nil
        #    private_dns_name=nil
        #    source_dest_check=nil
        #    group_set=nil
        #    attachment=nil
        #    association=nil
        #    tag_set=nil
        #  >
        #

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # Returns an array of all network interfaces that have been created
        #
        # AWS.network_interfaces.all
        #
        # ==== Returns
        #
        # Returns an array of all network interfaces
        #
        #>> AWS.network_interfaves.all
        #  <Fog::AWS::Compute::NetworkInterfaces
        #    filters={}
        #    [
        #      <Fog::AWS::Compute::NetworkInterface
        #        network_interface_id="eni-da5dc7ca",
        #        state=nil,
        #        request_id=nil,
        #        subnet_id="a9db1bcd-d215-a56f-b0ab-2398d7f37217",
        #        vpc_id="mock-vpc-id",
        #        availability_zone="mock-zone",
        #        description=nil,
        #        owner_id="",
        #        requester_id=nil,
        #        requester_managed="false",
        #        status="available",
        #        mac_address="00:11:22:33:44:55",
        #        private_ip_address="10.0.0.2",
        #        private_dns_name=nil,
        #        source_dest_check=true,
        #        group_set={},
        #        attachment={},
        #        association={},
        #        tag_set={}
        #      >
        #    ]
        #  >
        #

        def all(filters_arg = filters)
          filters = filters_arg
          data = service.describe_network_interfaces(filters).body
          load(data['networkInterfaceSet'])
        end

        # Used to retrieve a network interface
        # network interface id is required to get any information
        #
        # You can run the following command to get the details:
        # AWS.network_interfaces.get("eni-11223344")
        #
        # ==== Returns
        #
        #>> AWS.NetworkInterface.get("eni-11223344")
        #  <Fog::AWS::Compute::NetworkInterface
        #    network_interface_id="eni-da5dc7ca",
        #    state=nil,
        #    request_id=nil,
        #    subnet_id="a9db1bcd-d215-a56f-b0ab-2398d7f37217",
        #    vpc_id="mock-vpc-id",
        #    availability_zone="mock-zone",
        #    description=nil,
        #    owner_id="",
        #    requester_id=nil,
        #    requester_managed="false",
        #    status="available",
        #    mac_address="00:11:22:33:44:55",
        #    private_ip_address="10.0.0.2",
        #    private_dns_name=nil,
        #    source_dest_check=true,
        #    group_set={},
        #    attachment={},
        #    association={},
        #    tag_set={}
        #  >
        #

        def get(nic_id)
          if nic_id
            self.class.new(:service => service).all('network-interface-id' => nic_id).first
          end
        end
      end
    end
  end
end
