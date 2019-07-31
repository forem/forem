require "rails_helper"

RSpec.describe "Views an article", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  let!(:comment) { create(:comment, commentable: article) }
  let!(:child_comment) { create(:comment, parent: comment, commentable: article) }

  it "shows all comments" do
    create(:comment, commentable: article)
    visit "#{article.path}/comments"
    expect(page).to have_selector(".single-comment-node", visible: true, count: 3)
  end

  it "shows a thread" do
    visit "#{article.path}/comments/#{comment.id_code_generated}"
    expect(page).to have_selector(".single-comment-node", visible: true, count: 2)
    expect(page).to have_selector(".comment-deep-0#comment-node-#{comment.id}", visible: true, count: 1)
    expect(page).to have_selector(".comment-deep-1#comment-node-#{child_comment.id}", visible: true, count: 1)
  end
end
