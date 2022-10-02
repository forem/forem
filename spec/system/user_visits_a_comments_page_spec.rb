require "rails_helper"

RSpec.describe "Views an article", type: :system, js: true do
  let(:user) { create(:user) }
  let(:co_author) { create(:user) }
  let(:article) { create(:article, user: user, co_author_ids: [co_author.id]) }
  let(:ama_article) { create(:article, user: user, tags: "ama") }

  let!(:comment) { create(:comment, commentable: article) }
  let!(:child_comment) { create(:comment, parent: comment, commentable: article) }

  it "shows all comments" do
    create(:comment, commentable: article)
    visit "#{article.path}/comments"

    expect(page).to have_selector(".single-comment-node", visible: :visible, count: 3)
    expect(page).not_to have_selector(".spec-op-author")
  end

  it "shows op marker on author and co-author comments" do
    create(:comment, user: user, commentable: article)
    create(:comment, user: co_author, commentable: article)
    visit "#{article.path}/comments"

    expect(page).to have_selector(".spec-op-author[data-tooltip='Author']", visible: :visible, count: 2)
  end

  it "shows special op marker on ama articles" do
    create(:comment, user: user, commentable: ama_article)
    visit "#{ama_article.path}/comments"

    expect(page).to have_selector(".spec-op-author[data-tooltip='Ask Me Anything']", visible: :visible)
  end

  it "shows a thread" do
    visit "#{article.path}/comments/#{comment.id_code_generated}"

    expect(page).to have_selector(".single-comment-node", visible: :visible, count: 2)
    expect(page).to have_selector(".comment--deep-0#comment-node-#{comment.id}", visible: :visible, count: 1)
    expect(page).to have_selector(".comment--deep-1#comment-node-#{child_comment.id}", visible: :visible, count: 1)
  end
end
