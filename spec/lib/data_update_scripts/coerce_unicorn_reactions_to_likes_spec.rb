require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220906190412_coerce_unicorn_reactions_to_likes.rb",
)

describe DataUpdateScripts::CoerceUnicornReactionsToLikes do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:unicorn_reaction) { create(:reaction, user: user, reactable: article, category: "like") }

  before do
    unicorn_reaction.update_attribute(:category, "unicorn") # This skips validations
  end

  it "deletes unicorn reactions that have a like reaction on the same reactable by the same user" do
    create(:reaction, user: user, reactable: article, category: "like")

    described_class.new.run

    expect(Reaction.where(category: "unicorn")).to be_empty
    expect(article.reactions.count).to eq(1)
    expect(article.reactions.first.category).to eq("like")
  end

  it "flips unicorn reactions to like" do
    expect(unicorn_reaction.reload.category).to eq("unicorn")
    described_class.new.run

    expect(unicorn_reaction.reload.category).to eq("like")
  end
end
