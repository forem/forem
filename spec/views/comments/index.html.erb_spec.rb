require "rails_helper"

RSpec.describe "comments/index", type: :view do
  context "when the article is deleted" do
    before do
      assign(:on_comments_page, true)
      assign(:comment, Comment.new)
      assign(:podcast, nil)
      assign(:root_comment, nil)
      assign(:user, create(:user))
      assign(:commentable, nil)
      assign(:article, nil)
    end

    it "renders without error" do
      expect { render }.not_to raise_error
    end
  end
end
