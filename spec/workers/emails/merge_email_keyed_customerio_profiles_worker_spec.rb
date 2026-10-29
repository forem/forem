require "rails_helper"

RSpec.describe Emails::MergeEmailKeyedCustomerioProfilesWorker, type: :worker do
  let(:track_client) { instance_double(Customerio::Client, merge_customers: nil) }

  before do
    stub_const("CUSTOMERIO_TRACK_API", track_client)
    omniauth_mock_mlh_payload
  end

  def link(user, uid, at:)
    create(:identity, provider: "mlh", user: user, uid: uid, created_at: at)
  end

  it "merges the email-keyed person of a user linked after signup into the linked person" do
    user = create(:user)
    link(user, "core-1", at: user.created_at + 30.seconds)

    described_class.new.perform(user.id, user.id)

    expect(track_client).to have_received(:merge_customers).with("id", "core-1", "id", user.email)
  end

  it "skips users outside the range and users linked before signup" do
    outside = create(:user)
    link(outside, "core-2", at: outside.created_at + 30.seconds)
    pre_linked = create(:user)
    link(pre_linked, "core-3", at: pre_linked.created_at - 1.minute)

    described_class.new.perform(pre_linked.id, pre_linked.id)

    expect(track_client).not_to have_received(:merge_customers)
  end
end
