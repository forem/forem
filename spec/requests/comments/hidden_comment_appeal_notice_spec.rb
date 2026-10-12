require "rails_helper"

RSpec.describe "Hidden comment appeal notice" do
  let(:author) { create(:user) }
  let(:other_reader) { create(:user) }
  let(:article) { create(:article) }
  let(:hidden_body) { "buy cheap pills from my totally legit shop" }
  let!(:hidden_comment) do
    create(:comment, user: author, commentable: article, body_markdown: hidden_body).tap do |comment|
      comment.update_columns(score: -500)
    end
  end

  def notices_in(body)
    Nokogiri::HTML(body).css(".hidden-comment-appeal-notice")
  end

  # Signed in readers are served the edge-cached copy of the page (the Fastly VCL keys it on the
  # remember_user_token cookie), which is the same copy for every one of them.
  def get_as(user)
    sign_in user
    cookies["remember_user_token"] = "present"
    get article.path
  end

  before do
    create(:comment, commentable: article).update_columns(score: 5)
    Comments::Count.call(article, recalculate: true)
  end

  it "renders the same hidden, content-free placeholder for the author and for other readers" do
    get_as(author)
    author_notices = notices_in(response.body)
    expect(response.headers["Surrogate-Control"]).to be_present

    sign_out author
    get_as(other_reader)
    other_notices = notices_in(response.body)

    expect(author_notices.size).to eq(1)
    expect(other_notices.map(&:to_html)).to eq(author_notices.map(&:to_html))
    expect(author_notices.first["class"].split).to include("hidden")
    expect(author_notices.first["data-hidden-comment-author-id"]).to eq(author.id.to_s)
  end

  it "never includes the hidden comment's content" do
    get_as(other_reader)

    expect(response.body).not_to include(hidden_body)
  end

  it "links to the appeal form using query params that survive the Fastly edge" do
    get_as(author)

    link = notices_in(response.body).first.at_css("a")
    expect(link["href"]).to eq(appeal_path(source_type: "Comment", source_id: hidden_comment.id))
  end

  it "is not rendered for signed out readers" do
    get article.path

    expect(notices_in(response.body)).to be_empty
  end

  it "is rendered when the hidden comment is the only comment" do
    Comment.where.not(id: hidden_comment.id).destroy_all
    Comments::Count.call(article.reload, recalculate: true)

    get_as(author)

    expect(notices_in(response.body).size).to eq(1)
  end

  it "is not rendered for a deleted comment" do
    hidden_comment.update_columns(deleted: true)

    get_as(author)

    expect(notices_in(response.body)).to be_empty
  end

  context "with replies in the thread" do
    let(:parent) { create(:comment, commentable: article).tap { |c| c.update_columns(score: 5) } }
    let!(:hidden_reply) do
      create(:comment, commentable: article, parent: parent, user: author).tap { |c| c.update_columns(score: -500) }
    end

    it "places a hidden reply's placeholder under its visible parent" do
      get_as(author)

      within_parent = Nokogiri::HTML(response.body).css("#comment-node-#{parent.id} .hidden-comment-appeal-notice")
      expect(within_parent.pluck("data-hidden-comment-id")).to eq([hidden_reply.id.to_s])
    end

    it "does not make a hidden parent visible because its hidden reply has a placeholder" do
      parent.update_columns(score: -500)

      get_as(author)

      page = Nokogiri::HTML(response.body)
      expect(page.css("#comment-node-#{parent.id}")).to be_empty
      expect(page.css("#comment-node-#{hidden_reply.id}")).to be_empty
      expect(page.css(".hidden-comment-appeal-notice").pluck("data-hidden-comment-id"))
        .to include(parent.id.to_s, hidden_reply.id.to_s)
    end
  end
end
