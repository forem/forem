require "rails_helper"

RSpec.describe Notifications::RemoveBySpammer, type: :service do
  let(:spammer) { create(:user) }
  let(:recipient) { create(:user) }
  let(:other_user) { create(:user) }
  let(:article) { create(:article, user: spammer) }
  let(:comment) { create(:comment, user: spammer, commentable: article) }
  let(:comment_mention) { create(:mention, user: recipient, mentionable: comment) }
  let(:article_mention) { create(:mention, user: recipient, mentionable: article) }
  let(:other_comment) { create(:comment, user: other_user) }
  let(:other_mention) { create(:mention, user: recipient, mentionable: other_comment) }

  before do
    create(:notification, user: recipient, organization: nil, notifiable: comment)
    create(:notification, user: recipient, organization: nil, notifiable: comment_mention)
    create(:notification, user: recipient, organization: nil, notifiable: article_mention)
    create(:notification, user: recipient, organization: nil, notifiable: article, action: "Published")
    create(:notification, user: recipient, organization: nil, notifiable: other_comment)
    create(:notification, user: recipient, organization: nil, notifiable: other_mention)
  end

  it "removes comment, mention, and published article notifications from the spammer while keeping others" do
    described_class.call(spammer)

    expect(Notification.where(notifiable: comment)).not_to exist
    expect(Notification.where(notifiable: comment_mention)).not_to exist
    expect(Notification.where(notifiable: article_mention)).not_to exist
    expect(Notification.where(notifiable: article, action: "Published")).not_to exist
    expect(Notification.where(notifiable: other_comment)).to exist
    expect(Notification.where(notifiable: other_mention)).to exist
  end
end
