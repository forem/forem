require "rails_helper"

RSpec.describe "articles/show", type: :view do
  let(:user1) { create(:user) }
  let(:article1) { create(:article, user_id: user1.id, show_comments: true) }
  let(:helper) { Class.new { extend CommentsHelper } }

  before do
    assign(:user, user1)
    assign(:article, article1.decorate)
    assign(:comment, Comment.new)
    without_partial_double_verification do
      allow(view).to receive(:internal_navigation?).and_return(params[:i] == "i")
    end
  end

  def create_comment(parent_id = nil)
    create(
      :comment,
      user_id: user1.id,
      parent_id: parent_id || nil,
      commentable_id: article1.id,
      commentable_type: "Article",
    )
  end

  it "shows user title of the article" do
    render
    expect(rendered).to have_text(article1.title)
    expect(rendered).to have_css("#main-title")
  end

  it "shows user tags" do
    render
    expect(rendered).to have_css ".spec__tags"
    article1.tags.all? { |tag| expect(rendered).to have_text(tag.name) }
  end

  it "shows user content of the article" do
    render
    expect(rendered).to have_text(Nokogiri::HTML(article1.processed_html).text)
    expect(rendered).to have_css ".spec__body"
  end

  it "shows user new comment box" do
    render
    expect(rendered).to have_css("form.comment-form textarea")
    expect(rendered).to have_css("form.comment-form button[type='submit']")
  end

  it "shows a note about the canonical URL" do
    allow(article1).to receive(:canonical_url).and_return("https://example.com/lamas")
    render
    expect(rendered).to have_text("Originally published at")
    expect(rendered).to have_text("example.com")
  end
end
