module StripeMock
  module TestStrategies
    class Live < Base

      def create_product(params={})
        params = create_product_params(params)
        raise "create_product requires an :id" if params[:id].nil?
        delete_product(params[:id])
        Stripe::Product.create params
      end

      def delete_product(product_id)
        product = Stripe::Product.retrieve(product_id)
        Stripe::Plan.list(product: product_id).each(&:delete) if product.type == 'service'
        product.delete
      rescue Stripe::StripeError => e
        # do nothing
      end

      def create_plan(params={})
        raise "create_plan requires an :id" if params[:id].nil?
        delete_plan(params[:id])
        Stripe::Plan.create create_plan_params(params)
      end

      def delete_plan(plan_id)
        plan = Stripe::Plan.retrieve(plan_id)
        plan.delete
      rescue Stripe::StripeError => e
        # do nothing
      end

      def create_coupon(params={})
        delete_coupon create_coupon_params(params)[:id]
        super
      end

      def delete_coupon(id)
        coupon = Stripe::Coupon.retrieve(id)
        coupon.delete
      rescue Stripe::StripeError
        # do nothing
      end

      def upsert_stripe_object(object, attributes)
        raise UnsupportedRequestError.new "Updating or inserting Stripe objects in Live mode not supported"
      end

    end
  end
end
