module Fog
  module AWS
    class Compute
      class NetworkInterface < Fog::Model
        identity  :network_interface_id,        :aliases => 'networkInterfaceId'
        attribute :state
        attribute :request_id,                  :aliases => 'requestId'
        attribute :network_interface_id,        :aliases => 'networkInterfaceId'
        attribute :subnet_id,                   :aliases => 'subnetId'
        attribute :vpc_id,                      :aliases => 'vpcId'
        attribute :availability_zone,           :aliases => 'availabilityZone'
        attribute :description,                 :aliases => 'description'
        attribute :owner_id,                    :aliases => 'ownerId'
        attribute :requester_id,                :aliases => 'requesterId'
        attribute :requester_managed,           :aliases => 'requesterManaged'
        attribute :status,                      :aliases => 'status'
        attribute :mac_address,                 :aliases => 'macAddress'
        attribute :private_ip_address,          :aliases => 'privateIpAddress'
        attribute :private_ip_addresses,        :aliases => 'privateIpAddresses'
        attribute :private_dns_name,            :aliases => 'privateDnsName'
        attribute :source_dest_check,           :aliases => 'sourceDestCheck'
        attribute :group_set,                   :aliases => 'groupSet'
        attribute :attachment,                  :aliases => 'attachment'
        attribute :association,                 :aliases => 'association'
        attribute :tag_set,                     :aliases => 'tagSet'

        # Removes an existing network interface
        #
        # network_interface.destroy
        #
        # ==== Returns
        #
        # True or false depending on the result
        #

        def destroy
          requires :network_interface_id

          service.delete_network_interface(network_interface_id)
          true
        end

        # Create a network_interface
        #
        #  >> g = AWS.network_interfaces.new(:subnet_id => "subnet-someId", options)
        #  >> g.save
        #
        # options is an optional hash which may contain 'PrivateIpAddress', 'Description', 'GroupSet'
        #
        # == Returns:
        #
        # requestId and a networkInterface object
        #

        def save
          requires :subnet_id
          options = {
            'PrivateIpAddress'      => private_ip_address,
            'Description'           => description,
            'GroupSet'              => group_set,
          }
          options.delete_if {|key, value| value.nil?}
          data = service.create_network_interface(subnet_id, options).body['networkInterface']
          new_attributes = data.reject {|key,value| key == 'requestId'}
          merge_attributes(new_attributes)
          true
        end
      end
    end
  end
end
