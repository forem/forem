require "rails_helper"

RSpec.describe UserSubscriptions::IsSubscribedCacheChecker, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true) }
  let(:params) { { source_type: article.class_name, source_id: article.id } }

  it "checks if subscribed to a thing and returns true if they are" do
    create(:user_subscription,
           subscriber_id: user.id,
           subscriber_email: user.email,
           author_id: article.user_id,
           user_subscription_sourceable: article)

    expect(described_class.call(user, params)).to be(true)
  end

  it "checks if subscribed to a thing and returns false if they are not" do
    expect(described_class.call(user, params)).to be(false)
  end
end
