require "rails_helper"

RSpec.describe Favorites::Create, type: :service do
  let(:leader) { create(:user, :community_leader_level_1) }
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }

  it "favorites an article" do
    result = described_class.call(favoritable: article, user: leader)

    expect(result.success?).to be true
    expect(article.reload.favorited_by_user_id).to eq(leader.id)
    expect(article.favorited_at).to be_present
  end

  it "creates an audit log entry" do
    allow(Audit::Logger).to receive(:log).and_call_original

    described_class.call(favoritable: article, user: leader)

    expect(Audit::Logger).to have_received(:log).with(
      :moderator, leader, hash_including("action" => "favorite", "target_user_id" => author.id)
    )
  end

  it "favorites a comment" do
    comment = create(:comment, commentable: article, user: author)
    result = described_class.call(favoritable: comment, user: leader)

    expect(result.success?).to be true
    expect(comment.reload.favorited_by_user_id).to eq(leader.id)
  end

  it "rejects a non-leader" do
    result = described_class.call(favoritable: article, user: author)

    expect(result.success?).to be false
    expect(result.error).to eq(:not_a_leader)
    expect(article.reload.favorited_by_user_id).to be_nil
  end

  it "rejects an already-favorited record" do
    other_leader = create(:user, :community_leader_level_2)
    article.update!(favorited_by_user_id: other_leader.id, favorited_at: Time.current)

    result = described_class.call(favoritable: article, user: leader)

    expect(result.error).to eq(:already_favorited)
    expect(article.reload.favorited_by_user_id).to eq(other_leader.id)
  end

  it "rejects a user favoriting their own content" do
    own_article = create(:article, user: leader)

    result = described_class.call(favoritable: own_article, user: leader)

    expect(result.error).to eq(:self_favorite)
  end

  it "rejects an unpublished article" do
    draft = create(:article, user: author, published: false)

    result = described_class.call(favoritable: draft, user: leader)

    expect(result.error).to eq(:ineligible)
  end

  it "rejects a deleted comment" do
    comment = create(:comment, commentable: article, user: author, deleted: true)

    result = described_class.call(favoritable: comment, user: leader)

    expect(result.error).to eq(:ineligible)
  end

  it "rejects when the leader has no allowance remaining" do
    allow(Settings::UserExperience).to receive(:community_leader_l1_favorite_allowance).and_return(0)

    result = described_class.call(favoritable: article, user: leader)

    expect(result.error).to eq(:no_allowance)
    expect(article.reload.favorited_by_user_id).to be_nil
  end
end
