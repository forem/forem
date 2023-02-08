require "rails_helper"

RSpec.describe Moderator::BanishUser, type: :service do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :trusted) }
  let(:admin) { create(:user, :super_admin) }

  it "updates username, clears profile, and add BanishedUser record", :aggregate_failures do
    original_username = user.username
    sidekiq_perform_enqueued_jobs do
      described_class.call(user: user, admin: admin)
    end

    expect(user.username).to include "spam_"
    expect(user.profile.summary).to be_blank
    expect(user.profile.location).to be_blank
    expect(user.profile.website_url).to be_blank
    expect(user.profile.data).to be_empty
    expect(user.github_username).to be_blank
    expect(user.twitter_username).to be_blank
    expect(user.facebook_username).to be_blank
    expect(BanishedUser.exists?(username: original_username)).to be true
  end

  it "removes all their articles, comments, podcasts, abuse_reports, and vomit reactions", :aggregate_failures do
    article = create(:article, user: user, published: true)
    podcast = create(:podcast, creator: user)
    create(:podcast_ownership, owner: user, podcast: podcast)
    create(:comment, user: user, commentable: article)
    create(:reaction, category: "vomit", reactable: user, user: moderator)
    create(:feedback_message, :abuse_report, reporter_id: moderator.id, offender_id: user.id)

    expect do
      sidekiq_perform_enqueued_jobs do
        described_class.call(user: user, admin: admin)
      end
    end.to change { user.comments.count }.by(-1)
      .and change { user.articles.count }.by(-1)
      .and change { user.created_podcasts.count }.by(-1)
      .and change { Reaction.where(reactable: user).count }.by(-1)
      .and change { user.offender_feedback_messages.first.status }.from("Open").to("Resolved")
  end
end
