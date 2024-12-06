require 'spec_helper'

shared_examples 'Subscription Items API' do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:product) { stripe_helper.create_product(name: 'Silver Product') }
  let(:plan) { stripe_helper.create_plan(product: product.id, id: 'silver_plan') }
  let(:plan2) { stripe_helper.create_plan(amount: 100, id: 'one_more_1_plan', product: product.id) }
  let(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token) }
  let(:subscription) { Stripe::Subscription.create(customer: customer.id, items: [{ plan: plan.id }]) }

  context 'creates an item' do
    it 'when required params only' do
      item = Stripe::SubscriptionItem.create(plan: plan.id, subscription: subscription.id)

      expect(item.id).to match(/^test_si/)
      expect(item.plan.id).to eq(plan.id)
      expect(item.subscription).to eq(subscription.id)
    end
    it 'when no subscription params' do
      expect { Stripe::SubscriptionItem.create(plan: plan.id) }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.param).to eq('subscription')
        expect(e.message).to eq('Missing required param: subscription.')
      }
    end
    it 'when no plan params' do
      expect { Stripe::SubscriptionItem.create(subscription: subscription.id) }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.param).to eq('plan')
        expect(e.message).to eq('Missing required param: plan.')
      }
    end
  end

  context 'updates an item' do
    let(:item) { Stripe::SubscriptionItem.create(plan: plan.id, subscription: subscription.id, quantity: 2 ) }

    it 'updates plan' do
      updated_item = Stripe::SubscriptionItem.update(item.id, plan: plan2.id)

      expect(updated_item.plan.id).to eq(plan2.id)
    end
    it 'updates quantity' do
      updated_item = Stripe::SubscriptionItem.update(item.id, quantity: 23)

      expect(updated_item.quantity).to eq(23)
    end
    it 'when no existing item' do
      expect { Stripe::SubscriptionItem.update('some_id') }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.param).to eq('subscription_item')
        expect(e.message).to eq('No such subscription_item: some_id')
      }
    end
  end

  context 'retrieves a list of items' do
    before do
      Stripe::SubscriptionItem.create(plan: plan.id, subscription: subscription.id, quantity: 2 )
      Stripe::SubscriptionItem.create(plan: plan2.id, subscription: subscription.id, quantity: 20)
    end

    it 'retrieves all subscription items' do
      all = Stripe::SubscriptionItem.list(subscription: subscription.id)

      expect(all.count).to eq(2)
    end
    it 'when no subscription param' do
      expect { Stripe::SubscriptionItem.list }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.param).to eq('subscription')
        expect(e.message).to eq('Missing required param: subscription.')
      }
    end
  end
end
