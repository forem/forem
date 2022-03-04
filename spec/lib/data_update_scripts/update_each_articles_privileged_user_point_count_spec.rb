require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211104200856_update_each_articles_privileged_user_point_count.rb",
)

describe DataUpdateScripts::UpdateEachArticlesPrivilegedUserPointCount do
  it "updates articles scores" do
    article = create(:article)
    user = create(:user, :trusted)
    reaction = create(:thumbsdown_reaction, user: user, reactable: article)

    # Short-circuiting callbacks
    reaction.update_column(:points, 1_000_000)

    expect { described_class.new.run }.to change { article.reload.privileged_users_reaction_points_sum }.to(1_000_000)
  end
end
