require "rails_helper"

RSpec.describe Reactions::TouchUsersJob, type: :job do
  describe "#perform_now" do
    let(:article) { create(:article) }
    let(:article_reaction) { create(:reaction, reactable: article) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment) }
    let(:touched_at) { 5.minutes.from_now.beginning_of_minute }
    let(:article_reaction_user) { article_reaction.user }
    let(:comment_reaction_user) { comment_reaction.user }

    it "touches user updated_at and last_comment_at columns for an article reaction", :aggregate_failures do
      Timecop.freeze(touched_at) do
        described_class.perform_now(article_reaction.id)
        article_reaction_user.reload
        expect(article_reaction_user.updated_at).to eql(touched_at)
        expect(article_reaction_user.last_reaction_at).to eql(touched_at)
      end
    end

    it "touches user updated_at and last_comment_at columns for a comment reaction", :aggregate_failures do
      Timecop.freeze(touched_at) do
        described_class.perform_now(comment_reaction.id)
        comment_reaction_user.reload
        expect(comment_reaction_user.updated_at).to eql(touched_at)
        expect(comment_reaction_user.last_reaction_at).to eql(touched_at)
      end
    end
  end
end
