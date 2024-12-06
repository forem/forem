module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/purchase_reserved_node_offering'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :reserved_node_offering_id - required - (String)
        #    The unique identifier of the reserved node offering you want to purchase.
        # * :node_count - (Integer)
        #    The number of reserved nodes you want to purchase. Default: 1
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_PurchaseReservedNodeOffering.html
        def purchase_reserved_node_offering(options = {})
          reserved_node_offering_id = options[:reserved_node_offering_id]
          node_count                = options[:node_count]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::PurchaseReservedNodeOffering.new
          }

          params[:query]['Action']                   = 'PurchaseReservedNodeOffering'
          params[:query]['ReservedNodeOfferingId']   = reserved_node_offering_id if reserved_node_offering_id
          params[:query]['NodeCount']                = node_count if node_count

          request(params)
        end
      end
    end
  end
end
