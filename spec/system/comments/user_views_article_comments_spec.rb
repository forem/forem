require "rails_helper"

RSpec.describe "Visiting article comments", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, show_comments: true) }
  let!(:comment) { create(:comment, commentable: article, user: user) }
  let!(:child_comment) { create(:comment, commentable: article, parent: comment) }
  let!(:grandchild_comment) { create(:comment, commentable: article, parent: child_comment) }

  before do
    create(:comment, commentable: article, parent: comment)
    comments = create_list(:comment, 3, commentable: article)
    create(:comment, commentable: article, parent: comments.sample)
    sign_in user
  end

  context "when all comments" do
    before { visit "#{article.path}/comments" }

    it "displays comments" do
      expect(page).to have_selector(".single-comment-node", visible: :visible, count: 8)
    end

    it "displays child comments" do
      expect(page).to have_selector(".comment--deep-1", visible: :visible, count: 3)
    end

    it "displays grandchild comments" do
      expect(page).to have_selector(".comment--deep-2#comment-node-#{grandchild_comment.id}", visible: :visible,
                                                                                              count: 1)
    end
  end

  context "when root is specified" do
    before { visit "#{article.path}/comments/#{comment.id.to_s(26)}" } # rubocop:disable Rails/ToSWithArgument

    it "displays related comments" do
      expect(page).to have_selector(".single-comment-node", visible: :visible, count: 4)
    end

    it "displays child comments" do
      expect(page).to have_selector(".comment--deep-1", visible: :visible, count: 2)
    end

    it "displays grandchild comments" do
      expect(page).to have_selector(".comment--deep-2#comment-node-#{grandchild_comment.id}", visible: :visible,
                                                                                              count: 1)
    end
  end

  context "when looking into comment links" do
    it "uses the permalink for signed in users" do
      sign_in user
      visit article.path
      date_link = find("#comment-node-#{grandchild_comment.id} a.comment-date")
      expect(date_link[:href]).to end_with(grandchild_comment.path)
    end

    it "uses an anchor tag instead of permalink for signed out users" do
      sign_out user
      visit article.path
      date_link = find("#comment-node-#{grandchild_comment.id} a.comment-date")
      expected_path = "#{article.path}#comment-#{grandchild_comment.id_code}"
      expect(date_link[:href]).to end_with(expected_path)
    end
  end
end
