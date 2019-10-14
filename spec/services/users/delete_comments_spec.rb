require "rails_helper"

RSpec.describe Users::DeleteComments, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:buster) { double }

  before do
    create_list(:comment, 2, commentable: article, user: user)

    allow(buster).to receive(:bust_comment)
    allow(buster).to receive(:bust_user)
  end

  it "destroys user comments" do
    described_class.call(user, buster)
    expect(Comment.where(user_id: user.id).any?).to be false
  end

  it "busts cache" do
    described_class.call(user, buster)
    expect(buster).to have_received(:bust_comment).with(article).at_least(:once)
    expect(buster).to have_received(:bust_user).with(user)
  end
end
