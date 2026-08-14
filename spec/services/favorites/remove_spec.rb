require "rails_helper"

RSpec.describe Favorites::Remove, type: :service do
  let(:admin) { create(:user, :admin) }
  let(:leader) { create(:user, :community_leader_level_1) }

  it "clears the favorite from an article" do
    article = create(:article, favorited_by_user: leader, favorited_at: Time.current)

    result = described_class.call(favoritable: article, admin: admin)

    expect(result.success?).to be true
    expect(article.reload.favorited_by_user_id).to be_nil
    expect(article.favorited_at).to be_nil
  end

  it "clears the favorite from a comment" do
    comment = create(:comment, favorited_by_user: leader, favorited_at: Time.current)

    described_class.call(favoritable: comment, admin: admin)

    expect(comment.reload.favorited_by_user_id).to be_nil
  end

  it "audit-logs the removal" do
    article = create(:article, favorited_by_user: leader, favorited_at: Time.current)
    allow(Audit::Logger).to receive(:log).and_call_original

    described_class.call(favoritable: article, admin: admin)

    expect(Audit::Logger).to have_received(:log).with(
      :moderator, admin, hash_including("action" => "unfavorite", "previous_favoriter_id" => leader.id)
    )
  end
end
