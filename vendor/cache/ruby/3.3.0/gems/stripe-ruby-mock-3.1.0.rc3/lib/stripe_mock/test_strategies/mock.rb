module StripeMock
  module TestStrategies
    class Mock < Base

      def delete_product(product_id)
        if StripeMock.state == 'remote'
          StripeMock.client.destroy_resource('products', product_id)
        elsif StripeMock.state == 'local'
          StripeMock.instance.products.delete(product_id)
        end
      end

      def delete_plan(plan_id)
        if StripeMock.state == 'remote'
          StripeMock.client.destroy_resource('plans', plan_id)
        elsif StripeMock.state == 'local'
          StripeMock.instance.plans.delete(plan_id)
        end
      end

      def upsert_stripe_object(object, attributes = {})
        if StripeMock.state == 'remote'
          StripeMock.client.upsert_stripe_object(object, attributes)
        elsif StripeMock.state == 'local'
          StripeMock.instance.upsert_stripe_object(object, attributes)
        end
      end

    end
  end
end
