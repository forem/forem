require "rails_helper"

RSpec.describe Users::ConfirmFlagReactions, type: :service do
  let(:user) { create(:user, :trusted) }
  let(:user2) { create(:user, :trusted) }
  let(:article) { create(:article, user: user) }
  let(:article2) { create(:article, user: user) }
  let(:article3) { create(:article, user: user2) }
  let(:comment) { create(:comment, user: user, commentable: article2) }
  let(:comment2) { create(:comment, user: user, commentable: article) }

  it "doesn't fail when user has no reactions" do
    described_class.call(user)
  end

  def flag_reaction(reactable)
    create(:reaction, category: "vomit", status: "valid", reactable: reactable, user: user2)
  end

  context "with flag reactions" do
    let!(:user_flag) { flag_reaction(user) }
    let!(:article_flag) { flag_reaction(article) }
    let!(:article2_flag) { flag_reaction(article2) }
    let!(:comment_flag) { flag_reaction(comment) }
    let!(:comment2_flag) { flag_reaction(comment2) }

    it "updates statuses of the flag reactions to user, articles and comments", :aggregate_failures do
      described_class.call(user)
      expect(user_flag.reload.status).to eq("confirmed")
      expect(article_flag.reload.status).to eq("confirmed")
      expect(article2_flag.reload.status).to eq("confirmed")
      expect(comment_flag.reload.status).to eq("confirmed")
      expect(comment2_flag.reload.status).to eq("confirmed")
    end

    it "doesn't update non-flag (non-vomit) reactions", :aggregate_failures do
      reaction = create(:reaction, category: "thumbsup", status: "valid", reactable: user, user: user2)
      reaction2 = create(:reaction, category: "thumbsdown", status: "valid", reactable: article, user: user2)

      described_class.call(user)

      expect(reaction.reload.status).to eq("valid")
      expect(reaction2.reload.status).to eq("valid")
    end

    it "doesn't update other users reports", :aggregate_failures do
      user2_flag = create(:reaction, category: "vomit", status: "valid", reactable: user2, user: user)
      article3_flag = create(:reaction, category: "vomit", status: "valid", reactable: article3, user: user)

      described_class.call(user)

      expect(user2_flag.reload.status).to eq("valid")
      expect(article3_flag.reload.status).to eq("valid")
    end
  end
end
