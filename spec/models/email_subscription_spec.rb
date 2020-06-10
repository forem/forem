require "rails_helper"

RSpec.describe EmailSubscription, type: :model do
  subject { build(:email_subscription) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email_subscribable_id) }
    it { is_expected.to validate_presence_of(:email_subscribable_type) }
    it { is_expected.to validate_presence_of(:subscriber_id) }
    it { is_expected.to validate_inclusion_of(:email_subscribable_type).in_array(%w[Article]) }
    it { is_expected.to validate_uniqueness_of(:subscriber_id).scoped_to(:email_subscribable_type, :email_subscribable_id) }
  end

  describe "before_validation" do
    it "sets the author_id if it can be found" do
      article = create(:article)
      subscriber = create(:user)
      email_subscription = build(:email_subscription, email_subscribable: article, subscriber: subscriber, author: nil)
      email_subscription.validate!

      expect(email_subscription.author).to eq article.user
    end
  end
end
