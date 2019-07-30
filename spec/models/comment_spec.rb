require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:user)                  { create(:user, created_at: 3.weeks.ago) }
  let(:user2)                 { create(:user) }
  let(:article)               { create(:article, user_id: user.id, published: true) }
  let(:article_with_video)    { create(:article, :video, user_id: user.id, published: true) }
  let(:comment)               { create(:comment, user_id: user2.id, commentable_id: article.id) }
  let(:video_comment)         { create(:comment, user_id: user2.id, commentable_id: article_with_video.id) }
  let(:comment_2)             { create(:comment, user_id: user2.id, commentable_id: article.id) }
  let(:child_comment) do
    build(:comment, user_id: user.id, commentable_id: article.id, parent_id: comment.id)
  end

  describe "validations" do
    subject { described_class.new(commentable: article) }

    let(:article) { Article.new }

    before do
      allow(article).to receive(:touch).and_return(true)
    end

    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:commentable) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to have_many(:mentions).dependent(:destroy) }
    it { is_expected.to have_many(:notifications).dependent(:destroy) }
    it { is_expected.to have_many(:notification_subscriptions).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:commentable_id) }

    it { is_expected.to validate_presence_of(:body_markdown) }
    it { is_expected.to validate_uniqueness_of(:body_markdown).scoped_to(:user_id, :ancestry, :commentable_id, :commentable_type) }
    it { is_expected.to validate_length_of(:body_markdown).is_at_least(1).is_at_most(25_000) }
    it { is_expected.to validate_inclusion_of(:commentable_type).in_array(%w[Article PodcastEpisode]) }
  end

  it "gets proper generated ID code" do
    comment = described_class.new(id: 1)
    expect(comment.id_code_generated).to eq(comment.id.to_s(26))
  end

  it "generates character count before saving" do
    expect(comment.markdown_character_count).to eq(comment.body_markdown.size)
  end

  describe "#processed_html" do
    let(:comment) { create(:comment, commentable: article, body_markdown: "# hello\n\nhy hey hey") }

    it "converts body_markdown to proper processed_html" do
      expect(comment.processed_html.include?("<h1>")).to eq(true)
    end
  end

  # rubocop:disable RSpec/ExampleLength
  it "adds timestamp url if commentable has video and timestamp" do
    video_comment.body_markdown = "I like the part at 4:30"
    video_comment.save
    expect(video_comment.processed_html.include?(">4:30</a>")).to eq(true)
    video_comment.body_markdown = "I like the part at 4:30 and 5:50"
    video_comment.save
    expect(video_comment.processed_html.include?(">5:50</a>")).to eq(true)
    video_comment.body_markdown = "I like the part at 5:30 and :55"
    video_comment.save
    expect(video_comment.processed_html.include?(">:55</a>")).to eq(true)
    video_comment.body_markdown = "I like the part at 52:30"
    video_comment.save
    expect(video_comment.processed_html.include?(">52:30</a>")).to eq(true)
    video_comment.body_markdown = "I like the part at 1:52:30 and 1:20"
    video_comment.save
    expect(video_comment.processed_html.include?(">1:52:30</a>")).to eq(true)
    expect(video_comment.processed_html.include?(">1:20</a>")).to eq(true)
  end
  # rubocop:enable RSpec/ExampleLength

  it "does not add timestamp if commentable does not have video" do
    comment.body_markdown = "I like the part at 1:52:30 and 1:20"
    comment.save
    expect(comment.processed_html.include?(">1:52:30</a>")).to eq(false)
  end

  it "adds rel=nofollow to links" do
    comment.body_markdown = "this is a comment with a link: http://dev.to"
    comment.save
    expect(comment.processed_html.include?('rel="nofollow"')).to eq(true)
  end

  it "adds a mention url if user is mentioned like @mention" do
    comment.body_markdown = "Hello @#{user.username}, you are cool."
    comment.save
    expect(comment.processed_html.include?("/#{user.username}")).to eq(true)
    expect(comment.processed_html.include?("href")).to eq(true)
    expect(comment.processed_html.include?("Hello <a")).to eq(true)
  end

  it "not double wrap an already-linked mention" do
    comment.body_markdown = "Hello <a href='/#{user.username}'>@#{user.username}</a>, you are cool."
    comment.save
    expect(comment.processed_html.scan(/href/).count).to eq(1)
  end

  it "does not wrap email mention with username" do
    comment.body_markdown = "Hello hello@#{user.username}.com, you are cool."
    comment.save
    expect(comment.processed_html.include?("/#{user.username}")).to eq(false)
  end

  it "only mentions users who are actual users" do
    comment.body_markdown = "Hello @hooper, you are cool."
    comment.save
    expect(comment.processed_html.include?("/hooper")).to eq(false)
  end

  it "mentions people if it is the first word" do
    comment.body_markdown = "@#{user.username}, you are cool."
    comment.save
    expect(comment.processed_html.include?("/#{user.username}")).to eq(true)
  end

  it "does case insentive mention recognition" do
    comment.body_markdown = "Hello @#{user.username.titleize}, you are cool."
    comment.save
    expect(comment.processed_html.include?("/#{user.username}")).to eq(true)
    expect(comment.processed_html.include?("href")).to eq(true)
    expect(comment.processed_html.include?("Hello <a")).to eq(true)
  end

  it "shortens long urls" do
    comment.update(body_markdown: "Hello https://longurl.com/#{'x' * 100}?#{'y' * 100}")
    expect(comment.processed_html.include?("...</a>")).to eq(true)
    expect(comment.processed_html.size).to be < 450
  end

  it "does not show year in readable time if not current year" do
    expect(comment.readable_publish_date).to eq(comment.created_at.strftime("%b %e"))
  end

  it "shows year in readable time if not current year" do
    comment.created_at = 1.year.ago
    last_year = 1.year.ago.year % 100
    expect(comment.readable_publish_date.include?("'#{last_year}")).to eq(true)
  end

  it "returns a path" do
    expect(comment.path).not_to be(nil)
  end

  it "returns the properly formed path" do
    expect(comment.path).to eq("/#{comment.user.username}/comment/#{comment.id_code_generated}")
  end

  it "returns root article if no parent comment" do
    expect(comment.parent_or_root_article).to eq(comment.commentable)
  end

  it "returns root parent comment if exists" do
    expect(child_comment.parent_or_root_article).to eq(comment)
  end

  it "properly indexes" do
    comment.index!
  end

  describe "#parent_user" do
    it "returns the root article's user if no parent comment" do
      expect(comment.parent_user).to eq(user)
    end

    it "returns the root parent comment's user if root parent comment exists" do
      expect(child_comment.parent_user).to eq(user2)
    end
  end

  describe "#title" do
    it "is no more than 80 characters" do
      expect(comment.title.length).to be <= 80
    end

    it "is allows title of greater length if passed" do
      expect(comment.title(5).length).to eq(5)
    end

    it "retains content from #processed_html" do
      comment.update_column(:processed_html, "Hello this is a post.") # Remove randomness
      text = comment.title.gsub("...", "").delete("\n")
      expect(comment.processed_html).to include CGI.unescapeHTML(text)
    end

    it "is converted to deleted if the comment is deleted" do
      comment.update_column(:deleted, true)
      expect(comment.title).to eq "[deleted]"
    end

    it "does not contain the wrong encoding" do
      comment.body_markdown = "It's the best post ever. It's so great."
      comment.save
      expect(comment.title).not_to include "&#39;"
    end
  end

  describe "#custom_css" do
    it "returns nothing when no ltag was used" do
      expect(comment.custom_css).to eq("")
    end

    it "returns proper liquid tag classes if used" do
      text = "{% devcomment #{comment.id_code_generated} %}"
      ltag_comment = create(:comment, commentable_id: create(:article).id, body_markdown: text)
      expect(ltag_comment.custom_css).not_to eq("")
    end
  end

  describe "validity" do
    it "is invalid if commentable is unpublished article" do
      article.update_column(:published, false)
      comment = build(:comment, user_id: user.id, commentable_id: article.id)
      expect(comment).not_to be_valid
    end
  end

  describe "tree" do
    let(:article2) { create(:article) }
    let!(:tree_comment) { create(:comment, commentable: article2) }
    let!(:child) { create(:comment, commentable: article2, parent: tree_comment) }
    let!(:tree_comment2) { create(:comment, commentable: article2) }

    before { tree_comment.update_column(:score, 1) }

    it "returns a full tree" do
      comments = described_class.tree_for(article2)
      expect(comments).to eq(tree_comment => { child => {} }, tree_comment2 => {})
    end

    it "returns part of the tree" do
      comments = described_class.tree_for(article2, 1)
      expect(comments).to eq(tree_comment => { child => {} })
    end
  end

  describe "deleted" do
    let(:child_comment) { create(:comment, commentable: article, parent: comment, user: user) }

    it "deletes the comment's notifications" do
      create(:notification, notifiable: comment, user: user2)
      create(:notification, notifiable: child_comment, user: user)
      perform_enqueued_jobs do
        child_comment.update(deleted: true)
        expect(child_comment.notifications).to be_empty
      end
    end

    it "updates the notifications of the ancestors and descendants" do
      create(:notification, notifiable: comment, user: user2)
      create(:notification, notifiable: child_comment, user: user)
      perform_enqueued_jobs do
        comment.update(deleted: true)
        expect(child_comment.notifications.first.json_data["comment"]["ancestors"][0]["title"]).to eq "[deleted]"
      end
    end
  end

  describe "when algolia auto-indexing/removal is triggered" do
    context "when destroying" do
      it "doesn't schedule an ActiveJob on destroy" do
        comment = create(:comment, commentable: article)
        expect do
          comment.destroy
        end.not_to have_enqueued_job.on_queue("algoliasearch")
      end
    end

    context "when record.deleted == false" do
      it "checks auto-indexing" do
        expect do
          create(:comment, user_id: user2.id, commentable_id: article.id)
        end.to have_enqueued_job.with(kind_of(described_class), "index!").on_queue("algoliasearch")
      end
    end

    context "when record.deleted == true" do
      it "checks auto-indexing" do
        comment.deleted = true
        expect do
          comment.save!
        end.to have_enqueued_job.with(kind_of(described_class), "remove_algolia_index").on_queue("algoliasearch")
      end
    end
  end

  include_examples "#sync_reactions_count", :article_comment
end
