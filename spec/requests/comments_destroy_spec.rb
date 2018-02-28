require "rails_helper"

RSpec.describe "CommentsUpdate", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
  end

  it "deletes childless article" do
    new_body = "NEW TITLE #{rand(100)}"
    comment = create(:comment, user_id: user.id, commentable_id: article.id)
    delete "/comments/#{comment.id}"
    expect(Comment.all.size).to eq(0)
  end

  it "deletes childless article" do
    new_body = "NEW TITLE #{rand(100)}"
    comment = create(:comment, user_id: user.id, commentable_id: article.id)
    comment_2 = create(:comment, user_id: user.id, commentable_id: article.id, parent_id: comment.id)
    delete "/comments/#{comment.id}"
    expect(Comment.first.deleted).to eq(true)
  end


  it "visits delete confirm" do
    new_body = "NEW TITLE #{rand(100)}"
    comment = create(:comment, user_id: user.id, commentable_id: article.id)
    get comment.path + "/delete_confirm"
    expect(response.body).to include("Are you sure you want to delete this comment")
  end

end
