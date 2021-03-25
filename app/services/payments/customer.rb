module Payments
  # A thin wrapper on Stripe Customers and Charges APIs
  # see: <https://stripe.com/docs/api/customers/object>,
  # <https://stripe.com/docs/api/charges>
  class Customer
    class << self
      def get(customer_id)
        request do
          Stripe::Customer.retrieve(customer_id)
        end
      end

      def create(**params)
        request do
          Stripe::Customer.create(**params)
        end
      end

      def save(customer)
        request do
          customer.save
        end
      end

      def create_source(customer_id, token)
        request do
          Stripe::Customer.create_source(customer_id, source: token)
        end
      end

      def get_source(customer, source_id)
        request do
          customer.sources.retrieve(source_id)
        end
      end

      def detach_source(customer_id, source_id)
        request do
          Stripe::Customer.detach_source(customer_id, source_id)
        end
      end

      def get_sources(customer, **params)
        request do
          customer.sources.list(**params)
        end
      end

      def charge(customer:, amount:, description:, card_id: nil)
        source = card_id || customer.default_source

        request do
          Stripe::Charge.create(
            customer: customer.id,
            source: source,
            amount: amount,
            description: description,
            currency: "usd",
          )
        end
      end

      private

      def request
        yield
      rescue Stripe::InvalidRequestError => e
        ForemStatsClient.increment("stripe.errors", tags: ["error:InvalidRequestError"])
        raise InvalidRequestError, e.message
      rescue Stripe::CardError => e
        ForemStatsClient.increment("stripe.errors", tags: ["error:CardError"])
        raise CardError, e.message
      rescue Stripe::StripeError => e
        Honeybadger.notify(e)
        ForemStatsClient.increment("stripe.errors", tags: ["error:StripeError"])
        raise PaymentsError, e.message
      end
    end
  end
end
