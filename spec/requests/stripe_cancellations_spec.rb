require "rails_helper"

RSpec.describe "StripeCancellations", type: :request do
  let(:user) { create(:user, :super_admin) }
  let(:mock_instance) { instance_double(MembershipService) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_event_client) { instance_double (Stripe::Event) }
  let(:stubbed_stripe_event)

  before do
    allow_any_instance_of(StripeCancellationsController).to receive(:verify_stripe_payload).and_return(:true)
    StripeMock.start
    sign_in user
    user.update(stripe_id_code: "CUS_123")
  end

  after { StripeMock.stop }

  it "mocks a stripe cancellation webhook" do
    event = StripeMock.mock_webhook_event(
      'customer.subscription.deleted',
      { :customer => user.stripe_id_code, :total_count => 1 })

    monthly_dues = event.data.object.items.data[0].plan.amount
      binding.pry
    post "/stripe_subscriptions", params: {
      amount: monthly_dues,
      stripe_token: stripe_helper.generate_card_token
    }

    post "/stripe_cancellations", params: event.as_json
    expect(user.monthly_dues).to eq(0)
  end

end