module Fog
  module AWS
    class Compute
      class InternetGateway < Fog::Model
        identity  :id,                          :aliases => 'internetGatewayId'
        attribute :attachment_set,              :aliases => 'attachmentSet'
        attribute :tag_set,                     :aliases => 'tagSet'

        def initialize(attributes={})
          super
        end

        # Attaches an existing internet gateway
        #
        # internet_gateway.attach(igw-id, vpc-id)
        #
        # ==== Returns
        #
        # True or false depending on the result
        #
        def attach(vpc_id)
          requires :id
          service.attach_internet_gateway(id, vpc_id)
          reload
        end

        # Detaches an existing internet gateway
        #
        # internet_gateway.detach(igw-id, vpc-id)
        #
        # ==== Returns
        #
        # True or false depending on the result
        #
        def detach(vpc_id)
          requires :id
          service.detach_internet_gateway(id, vpc_id)
          reload
        end

        # Removes an existing internet gateway
        #
        # internet_gateway.destroy
        #
        # ==== Returns
        #
        # True or false depending on the result
        #
        def destroy
          requires :id

          service.delete_internet_gateway(id)
          true
        end

        # Create an internet gateway
        #
        #  >> g = AWS.internet_gateways.new()
        #  >> g.save
        #
        # == Returns:
        #
        # requestId and a internetGateway object
        #
        def save
          data = service.create_internet_gateway.body['internetGatewaySet'].first
          new_attributes = data.reject {|key,value| key == 'requestId'}
          merge_attributes(new_attributes)
          true

          true
        end
      end
    end
  end
end
