require "rails_helper"

describe "Views an article" do
  let(:user) { create(:user) }
  let(:dir) { "../support/fixtures/sample_article.txt" }
  let(:template) { File.read(File.join(File.dirname(__FILE__), dir)) }
  let(:article) do
    create(:article,
           user_id: user.id,
           body_markdown: template.gsub("false", "true"),
           body_html: "")
  end

  let!(:comment) { create(:comment, commentable: article) }
  let!(:child_comment) { create(:comment, parent: comment, commentable: article) }

  before do
    create(:comment, commentable: article)
    sign_in user
  end

  it "shows all comments" do
    visit "#{article.path}/comments"
    expect(page).to have_selector(".single-comment-node", visible: true, count: 3)
  end

  it "shows a thread" do
    visit "#{article.path}/comments/#{comment.id}"
    expect(page).to have_selector(".single-comment-node", visible: true, count: 2)
    expect(page).to have_selector(".comment-deep-0#comment-node-#{comment.id}", visible: true, count: 1)
    expect(page).to have_selector(".comment-deep-1#comment-node-#{child_comment.id}", visible: true, count: 1)
  end
end
