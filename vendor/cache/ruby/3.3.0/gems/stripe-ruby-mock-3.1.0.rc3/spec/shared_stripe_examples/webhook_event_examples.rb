require 'spec_helper'

shared_examples 'Webhook Events API' do

  it "matches the list of webhooks with the folder of fixtures" do
    events = StripeMock::Webhooks.event_list.to_set
    file_names = Dir['./lib/stripe_mock/webhook_fixtures/*'].map {|f| File.basename(f, '.json')}.to_set
    # The reason we take the difference instead of compare equal is so
    # that a missing event name will show up in the test failure report.
    expect(events - file_names).to eq(Set.new)
    expect(file_names - events).to eq(Set.new)
  end


  it "first looks in spec/fixtures/stripe_webhooks/ for fixtures by default" do
    event = StripeMock.mock_webhook_event('account.updated')
    payload = StripeMock.mock_webhook_payload('account.updated')
    expect(event).to be_a(Stripe::Event)
    expect(event.id).to match /^test_evt_[0-9]+/
    expect(event.type).to eq('account.updated')

    expect(payload).to be_a(Hash)
    expect(payload[:id]).to match /^test_evt_[0-9]+/
    expect(payload[:type]).to eq('account.updated')
  end

  it "allows non-standard event names in the project fixture folder" do
    expect {
      event = StripeMock.mock_webhook_event('custom.account.updated')
      StripeMock.mock_webhook_payload('custom.account.updated')
    }.to_not raise_error
  end

  it "allows configuring the project fixture folder" do
    original_path = StripeMock.webhook_fixture_path

    StripeMock.webhook_fixture_path = './spec/_dummy/webhooks/'
    expect(StripeMock.webhook_fixture_path).to eq('./spec/_dummy/webhooks/')

    event = StripeMock.mock_webhook_event('dummy.event')
    payload = StripeMock.mock_webhook_payload('dummy.event')
    expect(event.val).to eq('success')
    expect(payload[:val]).to eq('success')

    StripeMock.webhook_fixture_path = original_path
  end

  it "generates an event and stores it in memory" do
    event = StripeMock.mock_webhook_event('customer.created')
    expect(event).to be_a(Stripe::Event)
    expect(event.id).to_not be_nil

    data = test_data_source(:events)
    expect(data[event.id]).to_not be_nil
    expect(data[event.id][:id]).to eq(event.id)
    expect(data[event.id][:type]).to eq('customer.created')
  end

  it "generates an id for a new event" do
    event_a = StripeMock.mock_webhook_event('customer.created')
    event_b = StripeMock.mock_webhook_event('customer.created')
    expect(event_a.id).to_not be_nil
    expect(event_a.id).to_not eq(event_b.id)

    data = test_data_source(:events)
    expect(data[event_a.id]).to_not be_nil
    expect(data[event_a.id][:id]).to eq(event_a.id)

    expect(data[event_b.id]).to_not be_nil
    expect(data[event_b.id][:id]).to eq(event_b.id)
  end

  it "handles stripe connect event when account is present" do
  	acc_12314 = 'acc_12314'
    event = StripeMock.mock_webhook_event('customer.created', account: acc_12314)
    expect(event[:account]).to eq(acc_12314)
  end

  it "retrieves an eveng using the event resource" do
    webhook_event = StripeMock.mock_webhook_event('plan.created')
    expect(webhook_event.id).to_not be_nil

    event = Stripe::Event.retrieve(webhook_event.id)
    expect(event).to_not be_nil
    expect(event.type).to eq 'plan.created'
  end

  it "takes a hash and deep merges into the data object" do
    event = StripeMock.mock_webhook_event('customer.created', {
      :account_balance => 12345
    })
    payload = StripeMock.mock_webhook_event('customer.created', {
      :account_balance => 12345
    })
    expect(event.data.object.account_balance).to eq(12345)
    expect(payload[:data][:object][:account_balance]).to eq(12345)
  end

  it "takes a hash and deep merges arrays in the data object" do
    event = StripeMock.mock_webhook_event('invoice.created', {
      :lines => {
        :data => [
          { :amount => 555,
            :plan => { :id => 'wh_test' }
          }
        ]
      }
    })
    expect(event.data.object.lines.data.first.amount).to eq(555)
    expect(event.data.object.lines.data.first.plan.id).to eq('wh_test')
    # Ensure data from invoice.created.json is still present
    expect(event.data.object.lines.data.first.type).to eq('subscription')
    expect(event.data.object.lines.data.first.plan.currency).to eq('usd')
  end

  it "can generate all events" do
    StripeMock::Webhooks.event_list.each do |event_name|
      expect { StripeMock.mock_webhook_event(event_name) }.to_not raise_error
    end
  end

  it "raises an error for non-existant event types" do
    expect {
      event = StripeMock.mock_webhook_event('cow.bell')
    }.to raise_error StripeMock::UnsupportedRequestError

    expect {
      StripeMock.mock_webhook_payload('cow.bell')
    }.to raise_error StripeMock::UnsupportedRequestError
  end

  it 'has actual created attribute' do
    time = Time.now.to_i

    evnt = StripeMock.mock_webhook_event('customer.subscription.updated')

    expect(evnt.created).to eq time
  end

  it 'when created param can be overrided' do
    time = Time.now.to_i - 1000

    evnt = StripeMock.mock_webhook_event('customer.subscription.updated', created: time)

    expect(evnt.created).to eq time
  end

  describe "listing events" do

    it "retrieves all events" do
      customer_created_event = StripeMock.mock_webhook_event('customer.created')
      expect(customer_created_event).to be_a(Stripe::Event)
      expect(customer_created_event.id).to_not be_nil

      plan_created_event = StripeMock.mock_webhook_event('plan.created')
      expect(plan_created_event).to be_a(Stripe::Event)
      expect(plan_created_event.id).to_not be_nil

      coupon_created_event = StripeMock.mock_webhook_event('coupon.created')
      expect(coupon_created_event).to be_a(Stripe::Event)
      expect(coupon_created_event).to_not be_nil

      invoice_created_event = StripeMock.mock_webhook_event('invoice.created')
      expect(invoice_created_event).to be_a(Stripe::Event)
      expect(invoice_created_event).to_not be_nil

      invoice_item_created_event = StripeMock.mock_webhook_event('invoiceitem.created')
      expect(invoice_item_created_event).to be_a(Stripe::Event)
      expect(invoice_item_created_event).to_not be_nil

      events = Stripe::Event.list

      expect(events.count).to eq(5)
      expect(events.map &:id).to include(customer_created_event.id, plan_created_event.id, coupon_created_event.id, invoice_created_event.id, invoice_item_created_event.id)
      expect(events.map &:type).to include('customer.created', 'plan.created', 'coupon.created', 'invoice.created', 'invoiceitem.created')
    end

    it "retrieves events with a limit(3)" do
      customer_created_event = StripeMock.mock_webhook_event('customer.created')
      expect(customer_created_event).to be_a(Stripe::Event)
      expect(customer_created_event.id).to_not be_nil

      plan_created_event = StripeMock.mock_webhook_event('plan.created')
      expect(plan_created_event).to be_a(Stripe::Event)
      expect(plan_created_event.id).to_not be_nil

      coupon_created_event = StripeMock.mock_webhook_event('coupon.created')
      expect(coupon_created_event).to be_a(Stripe::Event)
      expect(coupon_created_event).to_not be_nil

      invoice_created_event = StripeMock.mock_webhook_event('invoice.created')
      expect(invoice_created_event).to be_a(Stripe::Event)
      expect(invoice_created_event).to_not be_nil

      invoice_item_created_event = StripeMock.mock_webhook_event('invoiceitem.created')
      expect(invoice_item_created_event).to be_a(Stripe::Event)
      expect(invoice_item_created_event).to_not be_nil

      events = Stripe::Event.list(limit: 3)

      expect(events.count).to eq(3)
      expect(events.map &:id).to include(invoice_item_created_event.id, invoice_created_event.id, coupon_created_event.id)
      expect(events.map &:type).to include('invoiceitem.created', 'invoice.created', 'coupon.created')
    end

  end

  describe 'Subscription events' do
    it "Checks for billing items in customer.subscription.created" do
      subscription_created_event = StripeMock.mock_webhook_event('customer.subscription.created')
      expect(subscription_created_event).to be_a(Stripe::Event)
      expect(subscription_created_event.id).to_not be_nil
      expect(subscription_created_event.data.object.items.data.class).to be Array
      expect(subscription_created_event.data.object.items.data.length).to be 2
      expect(subscription_created_event.data.object.items.data.first).to respond_to(:plan)
      expect(subscription_created_event.data.object.items.data.first.id).to eq('si_00000000000000')
    end

    it "Checks for billing items in customer.subscription.deleted" do
      subscription_deleted_event = StripeMock.mock_webhook_event('customer.subscription.deleted')
      expect(subscription_deleted_event).to be_a(Stripe::Event)
      expect(subscription_deleted_event.id).to_not be_nil
      expect(subscription_deleted_event.data.object.items.data.class).to be Array
      expect(subscription_deleted_event.data.object.items.data.length).to be 2
      expect(subscription_deleted_event.data.object.items.data.first).to respond_to(:plan)
      expect(subscription_deleted_event.data.object.items.data.first.id).to eq('si_00000000000000')
    end

    it "Checks for billing items in customer.subscription.updated" do
      subscription_updated_event = StripeMock.mock_webhook_event('customer.subscription.updated')
      expect(subscription_updated_event).to be_a(Stripe::Event)
      expect(subscription_updated_event.id).to_not be_nil
      expect(subscription_updated_event.data.object.items.data.class).to be Array
      expect(subscription_updated_event.data.object.items.data.length).to be 2
      expect(subscription_updated_event.data.object.items.data.first).to respond_to(:plan)
      expect(subscription_updated_event.data.object.items.data.first.id).to eq('si_00000000000000')
    end

    it "Checks for billing items in customer.subscription.trial_will_end" do
      subscription_trial_will_end_event = StripeMock.mock_webhook_event('customer.subscription.trial_will_end')
      expect(subscription_trial_will_end_event).to be_a(Stripe::Event)
      expect(subscription_trial_will_end_event.id).to_not be_nil
      expect(subscription_trial_will_end_event.data.object.items.data.class).to be Array
      expect(subscription_trial_will_end_event.data.object.items.data.length).to be 2
      expect(subscription_trial_will_end_event.data.object.items.data.first).to respond_to(:plan)
      expect(subscription_trial_will_end_event.data.object.items.data.first.id).to eq('si_00000000000000')
    end
  end

  describe 'Invoices events' do
    it "Checks for billing items in invoice.payment_succeeded" do
      invoice_payment_succeeded = StripeMock.mock_webhook_event('invoice.payment_succeeded')
      expect(invoice_payment_succeeded).to be_a(Stripe::Event)
      expect(invoice_payment_succeeded.id).to_not be_nil
      expect(invoice_payment_succeeded.data.object.lines.data.class).to be Array
      expect(invoice_payment_succeeded.data.object.lines.data.length).to be 2
      expect(invoice_payment_succeeded.data.object.lines.data.first).to respond_to(:plan)
      expect(invoice_payment_succeeded.data.object.lines.data.first.id).to eq('sub_00000000000000')
    end
  end
end
