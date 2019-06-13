require "rails_helper"

RSpec.describe Mention, type: :model do
  let(:user)        { create(:user) }
  let(:article)     { create(:article, user_id: user.id) }
  let(:comment)     { create(:comment, user_id: user.id, commentable_id: article.id) }

  it "calls on Mentions::CreateAllJob" do
    described_class.create_all(comment) do
      expect(Mentions::CreateAllJob).to have_received(:perform_later).with(comment.id, "Comment")
    end
  end
end
