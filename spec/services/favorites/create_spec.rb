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

  describe "favoriting by community leaders" do
    before do
      allow(Settings::UserExperience)
        .to receive(:community_leader_l1_favorite_allowance).and_return(2)
    end

    it "allows a leader to spend their last favorite" do
      described_class.call(favoritable: create(:article, user: author), user: leader)

      result = described_class.call(favoritable: article, user: leader)

      expect(result.success?).to be true
      expect(article.reload.favorited_by_user_id).to eq(leader.id)
    end

    it "prevents favoriting by a leader past their budget" do
      2.times { described_class.call(favoritable: create(:article, user: author), user: leader) }

      result = described_class.call(favoritable: article, user: leader)

      expect(result.error).to eq(:no_allowance)
      expect(article.reload.favorited_by_user_id).to be_nil
      expect(article.reload.favorited_at).to be_nil
    end
  end

  describe "favoriting by regular users" do
    it "lets the user spend earned credits" do
      spender = create(:user, earned_favorites_count: 1)

      result = described_class.call(favoritable: article, user: spender)

      expect(result.success?).to be true
      expect(article.reload.favorited_by_user_id).to eq(spender.id)

      expect(spender.reload.earned_favorites_count).to eq(0)
    end

    it "prevents favoriting once their credits run out" do
      spender = create(:user, earned_favorites_count: 1)
      described_class.call(favoritable: article, user: spender)

      result = described_class.call(favoritable: create(:article, user: author), user: spender)

      expect(result.error).to eq(:no_allowance)
      expect(spender.reload.earned_favorites_count).to eq(0)
    end

    # The in-memory record still looks free, so this exercises the claim losing
    # the race rather than the precheck rejecting it.
    it "does not spend a credit when the claim loses the race" do
      spender = create(:user, earned_favorites_count: 1)
      stale = Article.find(article.id)
      Article.where(id: article.id)
        .update_all(favorited_by_user_id: create(:user).id, favorited_at: Time.current)

      result = described_class.call(favoritable: stale, user: spender)

      expect(result.error).to eq(:already_favorited)
      expect(spender.reload.earned_favorites_count).to eq(1)
    end
  end

  describe "granting favorite credit to the author" do
    it "grants a credit when an article is favorited" do
      expect { described_class.call(favoritable: article, user: leader) }
        .to change { author.reload.earned_favorites_count }.by(1)
    end

    it "grants a credit when a comment is favorited" do
      comment = create(:comment, commentable: article, user: author)

      expect { described_class.call(favoritable: comment, user: leader) }
        .to change { author.reload.earned_favorites_count }.by(1)
    end

    it "grants no credit when the favorite is rejected" do
      article.update!(favorited_by_user_id: create(:user).id, favorited_at: Time.current)

      expect { described_class.call(favoritable: article, user: leader) }
        .not_to change { author.reload.earned_favorites_count }
    end
  end
end
