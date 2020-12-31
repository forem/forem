require "rails_helper"

RSpec.describe Users::DeleteComments, type: :service do
  let(:user) { create(:user) }
  let(:trusted_user) { create(:user, :trusted) }
  let(:article) { create(:article) }
  let(:comment) { create(:comment, user: user, commentable: article) }

  before do
    create_list(:comment, 2, commentable: article, user: user)

    allow(EdgeCache::BustComment).to receive(:call)
    allow(EdgeCache::BustUser).to receive(:call)
  end

  it "destroys user comments" do
    comment
    described_class.call(user)
    expect(Comment.where(user_id: user.id).any?).to be false
  end

  it "removes comments from Elasticsearch" do
    comment
    sidekiq_perform_enqueued_jobs
    expect(comment.elasticsearch_doc).not_to be_nil
    sidekiq_perform_enqueued_jobs { described_class.call(user) }
    expect { comment.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
  end

  it "busts cache" do
    described_class.call(user)
    expect(EdgeCache::BustComment).to have_received(:call).with(article).at_least(:once)
    expect(EdgeCache::BustUser).to have_received(:call).with(user)
  end

  it "destroys moderation notifications properly" do
    create(:notification, notifiable: comment, action: "Moderation", user: trusted_user)
    described_class.call(user)
    expect(Notification.count).to eq 0
  end
end
