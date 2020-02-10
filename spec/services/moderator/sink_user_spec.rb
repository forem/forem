require "rails_helper"

RSpec.describe Moderator::SinkUser, type: :service do
  let(:moderator) { create(:user, :trusted) }
  let(:spam_user) do
    user = create(:user)
    create_list(:article, 3, user: user)
    user
  end
  let(:admin) { create(:user, :super_admin) }
  let(:vomit_reaction) { create(:reaction, reactable: spam_user, user: moderator) }

  describe "#vomit_all_articles" do
    it "vomits on all the reactable's articles" do
      described_class.call(reaction: vomit_reaction)
      article_reactions = spam_user.articles.map(&:reactions)
      category = article_reactions.map { |reaction_array| reaction_array.pluck(:category) }.flatten.uniq
      expect(category.length).to eq 1
      expect(category[0]).to eq "vomit"
    end

    it "creates a special status for the vomit reaction" do
      described_class.call(reaction: vomit_reaction)
      article_reactions = spam_user.articles.map(&:reactions)
      status = article_reactions.map { |reaction_array| reaction_array.pluck(:status) }.flatten.uniq
      expect(status.length).to eq 1
      expect(status[0]).to eq "bulk_submitted"
    end
  end

  describe "#confirm_vomits" do
    before { described_class.call(reaction: vomit_reaction) }

    it "confirms all the articles vomits" do
      described_class.confirm(reaction: vomit_reaction)
      article_reactions = spam_user.articles.map(&:reactions)
      status = article_reactions.map { |reaction_array| reaction_array.pluck(:status) }.flatten.uniq
      expect(status.length).to eq 1
      expect(status[0]).to eq "confirmed"
    end
  end
end
