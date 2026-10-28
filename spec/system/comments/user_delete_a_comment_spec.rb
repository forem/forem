require "rails_helper"

RSpec.describe "Deleting Comment" do
  let(:user) { create(:user) }
  let(:article) do
    create(:article, user_id: user.id, show_comments: true)
  end
  let(:comment) { create(:comment, commentable: article, commentable_type: "Article", user: user) }

  before do
    sign_in user
  end

  it "deletes the comment and returns to the article page", :aggregate_failures do
    visit "#{comment.path}/delete_confirm"

    expect { click_on("Delete") }.to change(Comment, :count).by(-1)
    expect(page).to have_current_path(article.path)
  end
end
