module StripeMock
  module RequestHandlers
    module Helpers
      def add_coupon_to_object(object, coupon)
        discount_attrs = {}.tap do |attrs|
          attrs[object[:object]]         = object[:id]
          attrs[:coupon]                 = coupon
          attrs[:start]                  = Time.now.to_i
          attrs[:end]                    = (DateTime.now >> coupon[:duration_in_months].to_i).to_time.to_i if coupon[:duration] == 'repeating'
        end

        object[:discount] = Stripe::Discount.construct_from(discount_attrs)
        object
      end

      def delete_coupon_from_object(object)
        object[:discount] = nil
        object
      end
    end
  end
end
