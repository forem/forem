require "rails_helper"

RSpec.describe "StripeCancellations", type: :request do
  let(:user) { create(:user) }
  let(:stripe_helper) { StripeMock.create_test_helper }

  before do
    StripeMock.start
    allow_any_instance_of(StripeCancellationsController).to receive(:verify_stripe_signature).and_return(true)
  end

  after { StripeMock.stop }

  # rubocop:disable RSpec/ExampleLength
  it "mocks a stripe cancellation webhook" do
    customer = Stripe::Customer.create(
      email: user.email,
      source: stripe_helper.generate_card_token,
    )
    MembershipService.new(customer, user, 12).subscribe_customer
    user.reload
    expect(user.monthly_dues).not_to eq(0)

    event = StripeMock.mock_webhook_event(
      "customer.subscription.deleted",
      customer: user.stripe_id_code, total_count: 1,
    )
    post "/stripe_cancellations", params: event.as_json
    user.reload
    expect(user.monthly_dues).to eq(0)
    expect(response).to have_http_status(200)
  end
  # rubocop:enable RSpec/ExampleLength
end
