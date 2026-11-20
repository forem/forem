require "rails_helper"

RSpec.describe "Visiting article comments" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, show_comments: true, with_tags: false, with_main_image: false) }
  let!(:comment) { create(:comment, commentable: article, user: user) }
  let!(:child_comment) { create(:comment, commentable: article, parent: comment, user: user) }
  let!(:grandchild_comment) { create(:comment, commentable: article, parent: child_comment, user: user) }

  context "when viewing the comment tree" do
    before do
      create(:comment, commentable: article, parent: comment, user: user)
      comments = create_list(:comment, 3, commentable: article, user: user)
      create(:comment, commentable: article, parent: comments.sample, user: user)
      sign_in user
    end

    it "displays all comments and root-filtered comment subtrees", :aggregate_failures do
      visit "#{article.path}/comments"

      expect(page).to have_css(".single-comment-node", visible: :visible, count: 8)
      expect(page).to have_css(".comment--deep-1", visible: :visible, count: 3)
      expect(page).to have_css(
        ".comment--deep-2#comment-node-#{grandchild_comment.id}",
        visible: :visible,
        count: 1,
      )

      visit "#{article.path}/comments/#{comment.id.to_s(26)}"

      expect(page).to have_css(".single-comment-node", visible: :visible, count: 4)
      expect(page).to have_css(".comment--deep-1", visible: :visible, count: 2)
      expect(page).to have_css(
        ".comment--deep-2#comment-node-#{grandchild_comment.id}",
        visible: :visible,
        count: 1,
      )
    end
  end

  context "when looking into comment links" do
    it "uses an anchor tag for signed out users and the permalink for signed in users", :aggregate_failures do
      visit article.path
      date_link = find("#comment-node-#{grandchild_comment.id} a.comment-date")
      expected_path = "#{article.path}#comment-#{grandchild_comment.id_code}"
      expect(date_link[:href]).to end_with(expected_path)

      sign_in user
      visit article.path
      date_link = find("#comment-node-#{grandchild_comment.id} a.comment-date")
      expect(date_link[:href]).to end_with(grandchild_comment.path)
    end
  end
end
