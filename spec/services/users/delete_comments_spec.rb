require "rails_helper"

RSpec.describe Users::DeleteComments, type: :service do
  let(:user) { create(:user) }

  it "destroys user comments" do
    create_list(:comment, 2, commentable: article, user: user)
    described_class.call(user)
    expect(Comment.where(user_id: user.id).any?).to be false
  end
end
