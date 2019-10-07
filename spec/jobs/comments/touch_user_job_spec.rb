require "rails_helper"

RSpec.describe Comments::TouchUserJob, type: :job do
  describe "#perform_now" do
    let!(:article) { FactoryBot.create(:article) }
    let!(:comment) { FactoryBot.create(:comment, commentable: article) }
    let(:user) { comment.user }
    let(:touched_at) { 5.minutes.from_now.beginning_of_minute }

    it "touches user updated_at and last_comment_at columns", :aggregate_failures do
      Timecop.freeze(touched_at) do
        described_class.perform_now(comment.id)
        user.reload
        expect(user.updated_at).to eql(touched_at)
        expect(user.last_comment_at).to eql(touched_at)
      end
    end
  end
end
