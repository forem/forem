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

  it "soft-deletes user comments" do
    comment
    described_class.call(user)
    expect(Comment.where(user_id: user.id).any?).to be true
    expect(Comment.where(user_id: user.id).all?(&:deleted)).to be true
  end

  it "busts cache" do
    described_class.call(user)
    expect(EdgeCache::BustComment).to have_received(:call).with(instance_of(Comment)).at_least(:once)
    expect(EdgeCache::BustUser).to have_received(:call).with(user)
  end

  it "destroys moderation notifications properly" do
    create(:notification, notifiable: comment, action: "Moderation", user: trusted_user)
    described_class.call(user)
    expect(Notification.count).to eq 0
  end

  context "when user has comments with children" do
    let(:user_with_children) { create(:user) }
    let(:article_2) { create(:article) }
    let(:parent_comment) { create(:comment, user: user_with_children, commentable: article_2) }
    let(:child_comment) do
      create(:comment, user: trusted_user, commentable: article_2, parent_id: parent_comment.id)
    end

    before do
      parent_comment
      child_comment
    end

    it "soft-deletes parent comment only" do
      described_class.call(user_with_children)
      expect(parent_comment.reload.deleted).to be true
      expect(child_comment.reload.deleted).to be false
    end

    it "preserves comment tree structure" do
      initial_count = Comment.count
      described_class.call(user_with_children)
      expect(Comment.count).to eq initial_count
      expect(child_comment.reload.parent_id).to eq parent_comment.id
    end
  end
end
