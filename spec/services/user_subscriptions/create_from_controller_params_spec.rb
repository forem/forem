require "rails_helper"

RSpec.describe UserSubscriptions::CreateFromControllerParams, type: :service do
  let(:subscriber) { create(:user) }

  it "returns an error for an invalid source type" do
    source = create(:comment)
    user_subscription_params = { source_type: source.class.name, source_id: source.id,
                                 subscriber_email: subscriber.email }
    user_subscription = described_class.call(subscriber, user_subscription_params)

    expect(user_subscription.data).to be_nil
    expect(user_subscription.success).to be false
    expect(user_subscription.error).to eq "Invalid source_type."
  end

  it "returns an error for an invalid source" do
    source = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
    user_subscription_params = { source_type: source.class.name, source_id: source.id + 999,
                                 subscriber_email: subscriber.email }
    user_subscription = described_class.call(subscriber, user_subscription_params)

    expect(user_subscription.data).to be_nil
    expect(user_subscription.success).to be false
    expect(user_subscription.error).to eq "Source not found."
  end

  # TODO: [@forem/delightful]: re-enable this once email confirmation is re-enabled
  it "returns an error for an email mismatch" do
    skip "email confirmation disabled"
    source = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
    user_subscription_params = { source_type: source.class.name, source_id: source.id,
                                 subscriber_email: "old@email.com" }
    user_subscription = described_class.call(subscriber, user_subscription_params)

    expect(user_subscription.data).to be_nil
    expect(user_subscription.success).to be false
    expect(user_subscription.error).to eq "Subscriber email mismatch."
  end

  it "returns an error if a UserSubscription can't be created" do
    source = create(:article, :with_user_subscription_tag_role_user)
    user_subscription_params = { source_type: source.class.name, source_id: source.id,
                                 subscriber_email: subscriber.email }
    user_subscription = described_class.call(subscriber, user_subscription_params)

    expect(user_subscription.data).to be_nil
    expect(user_subscription.success).to be false
    expect(user_subscription.error).to eq "User subscriptions are not enabled for the source."
  end

  it "creates a UserSubscription" do
    source = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
    user_subscription_params = { source_type: source.class.name, source_id: source.id,
                                 subscriber_email: subscriber.email }
    user_subscription = described_class.call(subscriber, user_subscription_params)

    expect(user_subscription.data).to be_an_instance_of UserSubscription
    expect(user_subscription.data.user_subscription_sourceable_type).to eq source.class.name
    expect(user_subscription.data.user_subscription_sourceable_id).to eq source.id
    expect(user_subscription.data.subscriber_email).to eq subscriber.email
    expect(user_subscription.data.subscriber_id).to eq subscriber.id
    expect(user_subscription.data.author_id).to eq source.user.id
    expect(user_subscription.success).to be true
    expect(user_subscription.error).to be_nil
  end
end
