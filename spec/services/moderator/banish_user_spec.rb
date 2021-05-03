require "rails_helper"

RSpec.describe Moderator::BanishUser, type: :service do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :trusted) }
  let(:admin) { create(:user, :super_admin) }

  it "updates the user's username" do
    sidekiq_perform_enqueued_jobs do
      described_class.call(user: user, admin: admin)
    end
    expect(user.username).to include "spam_"
  end

  it "removes all their articles" do
    create(:article, user: user, published: true)
    sidekiq_perform_enqueued_jobs

    sidekiq_perform_enqueued_jobs do
      described_class.call(user: user, admin: admin)
    end
    expect(user.articles.count).to eq 0
  end

  it "removes all their comments" do
    article = create(:article, user: user, published: true)
    create(:comment, user: user, commentable: article)
    sidekiq_perform_enqueued_jobs

    sidekiq_perform_enqueued_jobs do
      described_class.call(user: user, admin: admin)
    end
    expect(user.comments.count).to eq 0
  end

  it "creates a BanishedUser record with their original username" do
    original_username = user.username
    sidekiq_perform_enqueued_jobs do
      described_class.call(user: user, admin: admin)
    end
    expect(BanishedUser.exists?(username: original_username)).to be true
  end

  it "deletes existing vomit reactions on the banished user" do
    create(:reaction, category: "vomit", reactable: user, user: moderator)
    sidekiq_perform_enqueued_jobs do
      described_class.call(user: user, admin: admin)
    end
    expect(Reaction.where(reactable: user).count).to eq 0
  end
end
