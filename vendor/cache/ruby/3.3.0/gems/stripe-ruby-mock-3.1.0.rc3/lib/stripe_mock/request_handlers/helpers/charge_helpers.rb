module StripeMock
  module RequestHandlers
    module Helpers

      def add_refund_to_charge(refund, charge)
        refunds = charge[:refunds]
        refunds[:data] << refund
        refunds[:total_count] = refunds[:data].count

        charge[:amount_refunded] = refunds[:data].reduce(0) {|sum, r| sum + r[:amount].to_i }
        charge[:refunded] = true
      end

    end
  end
end
