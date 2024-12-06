module Fog
  module AWS
    class Compute
      class Subnet < Fog::Model
        identity  :subnet_id,                   :aliases => 'subnetId'
        attribute :state
        attribute :vpc_id,                      :aliases => 'vpcId'
        attribute :cidr_block,                  :aliases => 'cidrBlock'
        attribute :available_ip_address_count,  :aliases => 'availableIpAddressCount'
        attribute :availability_zone,           :aliases => 'availabilityZone'
        attribute :tag_set,                     :aliases => 'tagSet'
        attribute :map_public_ip_on_launch,     :aliases => 'mapPublicIpOnLaunch'
        attribute :default_for_az,              :aliases => 'defaultForAz'

        def ready?
          requires :state
          state == 'available'
        end

        def network_interfaces
          service.network_interfaces.all('subnet-id' => [self.identity])
        end

        # Removes an existing subnet
        #
        # subnet.destroy
        #
        # ==== Returns
        #
        # True or false depending on the result
        #

        def destroy
          requires :subnet_id

          service.delete_subnet(subnet_id)
          true
        end

        # Create a subnet
        #
        #  >> g = AWS.subnets.new(:vpc_id => "vpc-someId", :cidr_block => "10.0.0.0/24")
        #  >> g.save
        #
        # == Returns:
        #
        # requestId and a subnet object
        #

        def save
          requires :vpc_id, :cidr_block
          options = {}
          options['AvailabilityZone'] = availability_zone if availability_zone
          data = service.create_subnet(vpc_id, cidr_block, options).body['subnet']
          new_attributes = data.reject {|key,value| key == 'requestId'}
          merge_attributes(new_attributes)
          true

          true
        end
      end
    end
  end
end
