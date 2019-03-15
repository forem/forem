require "rails_helper"

RSpec.describe Notifications::Reactions::Send, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:another_user) { create(:user) }
  let(:article_reaction) { create(:reaction, reactable: article, user: another_user) }

  it "doesn't send if a user reacts to their own content" do
    own_reaction = create(:reaction, user: user, reactable: article)
    expect do
      described_class.call(own_reaction, user)
    end.not_to change(Notification, :count)
  end

  it "doesn't send if a reaction is negative" do
    article_reaction.update_column(:points, -10)
    expect do
      described_class.call(article_reaction, user)
    end.not_to change(Notification, :count)
  end

  it "doesn't send if notifications are disabled" do
    article.update_column(:receive_notifications, false)
    expect do
      described_class.call(article_reaction, user)
    end.not_to change(Notification, :count)
  end
end
