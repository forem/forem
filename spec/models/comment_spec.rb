# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:user)                  { create(:user) }
  let(:user2)                 { create(:user) }
  let(:article)               { create(:article, user_id: user.id, published: true) }
  let(:article_with_video)    { create(:article, :video, user_id: user.id, published: true) } # :video is a trait, see articles.rb
  let(:comment)               { create(:comment, user_id: user2.id, commentable_id: article.id) }
  let(:video_comment)         { create(:comment, user_id: user2.id, commentable_id: article_with_video.id) }
  let(:comment_2)             { create(:comment, user_id: user2.id, commentable_id: article.id) }
  let(:child_comment) do
    build(:comment, user_id: user.id, commentable_id: article.id, parent_id: comment.id)
  end

  before { Notification.send_new_comment_notifications(comment) }

  it "gets proper generated ID code" do
    expect(comment.id_code_generated).to eq(comment.id.to_s(26))
  end

  it "generates character count before saving" do
    expect(comment.markdown_character_count).to eq(comment.body_markdown.size)
  end

  context "when comment is already posted" do
    before do
      Notification.send_new_comment_notifications(comment_2)
      comment_2.update(ancestry: comment.ancestry,
                       body_markdown: comment.body_markdown,
                       commentable_type: comment.commentable_type,
                       commentable_id: comment.commentable_id)
    end

    it "does not allow for double posts" do
      expect(comment_2).not_to be_valid
    end

    it "does allow for double posts if body is not the same" do
      comment_2.update(body_markdown: comment.body_markdown + " hey hey")
      expect(comment_2).to be_valid
    end
  end

  describe "#processed_html" do
    let(:comment) do
      create(:comment,
              commentable_id: article.id,
              body_markdown: "# hello\n\nhy hey hey")
    end

    it "converts body_markdown to proper processed_html" do
      expect(comment.processed_html.include?("<h1>")).to eq(true)
    end
  end

  it "adds timestamp url if commentable has video and timestamp" do
    Notification.send_new_comment_notifications(video_comment)
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

  it "does not add timestamp if commentable does not have video" do
    comment.body_markdown = "I like the part at 1:52:30 and 1:20"
    comment.save
    expect(comment.processed_html.include?(">1:52:30</a>")).to eq(false)
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
    comment.body_markdown = "Hello https://longurl.com/dsjkdsdsjdsdskhjdsjbhkdshjdshudsdsbhdsbiudsuidsuidsuidsuidsuidsuidsiudsiudsuidsuisduidsuidsiuiuweuiweuiewuiweuiweuiew?sdhiusduisduidsiudsuidsiusdiusdiuewiuewiuewiuweiuweiuweiuewiuweuiweuiewibsdiubdsiubdsisbdiudsbsdiusdbiu" # rubocop:disable Metrics/LineLength
    comment.save
    expect(comment.processed_html.include?("...</a>")).to eq(true)
    expect(comment.processed_html.size).to be < 450
  end

  it "does not show year in readable time if not current year" do
    expect(comment.readable_publish_date).to eq(comment.created_at.strftime("%b %e"))
  end

  it "shows year in readable time if not current year" do
    comment.created_at = 1.years.ago
    last_year = 1.year.ago.year % 100
    expect(comment.readable_publish_date.include?("'#{last_year}")).to eq(true)
  end

  it "returns a path" do
    expect(comment.path).not_to be(nil)
  end

  it "returns name_of_user" do
    expect(comment.name_of_user).to eq(comment.user.name)
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

    it "retains content from #processed_html" do
      text = comment.title.gsub("...", "").gsub(/\n/, "")
      expect(comment.processed_html).to include CGI.unescapeHTML(text)
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

  describe "#sharemeow_link" do
    it "uses ShareMeowClient" do
      allow(ShareMeowClient).to receive(:image_url).and_return("www.test.com")
      comment.sharemeow_link
      expect(ShareMeowClient).to have_received(:image_url)
    end
  end

  # describe "::StreamRails::Activity(notification callbacks)" do
  #   before do
  #     StreamRails.enabled = true
  #     allow(StreamNotifier).to receive(:new).and_call_original
  #   end

  #   after { StreamRails.enabled = false }

  #   context "when a comment without ancestor is created" do
  #     let(:test_comment) { build(:comment, commentable_id: article.id) }

  #     before { allow(test_comment).to receive(:send_email_notification).and_call_original }

  #     it "notifies the author" do
  #       test_comment.save!
  #       expect(StreamNotifier).to have_received(:new).at_least(:once)
  #     end

  #     it "does not notify author if self is author" do
  #       test_comment.user = user
  #       test_comment.save
  #       expect(StreamNotifier).not_to have_received(:new).with(user.id)
  #       expect(test_comment).not_to have_received :send_email_notification
  #     end

  #     it "does not notify anybody else" do
  #       test_comment.save
  #       expect(StreamNotifier).not_to have_received(:new).with(test_comment.user_id)
  #     end
  #   end

  #   context "when a comment with ancestor is created" do
  #     let(:nest_comment_1) { create(:comment, commentable_id: article.id) }
  #     let(:nest_comment_2) do
  #       create(:comment, parent_id: nest_comment_1.id, commentable_id: article.id)
  #     end
  #     let(:author_comment) do
  #       create(:comment, parent_id: nest_comment_2.id,
  #                        commentable_id: article.id, user_id: user.id)
  #     end
  #     let(:nest_comments_authors) { [nest_comment_1.user_id, nest_comment_2.user_id] }

  #     before do
  #       StreamRails.enabled = false
  #       nest_comments_authors # this needs to be evoked before StreamRails is enabled
  #       StreamRails.enabled = true
  #     end

  #     it "notifies all the ancestors" do
  #       create(:comment, parent_id: nest_comment_2.id, commentable_id: article.id)
  #       nest_comments_authors.each do |id|
  #         expect(StreamNotifier).to have_received(:new).with(id).at_least(:once)
  #       end
  #     end

  #     it "does not notifies the author" do
  #       create(:comment, parent_id: nest_comment_2.id, commentable_id: article.id)
  #       expect(StreamNotifier).not_to have_received(:new).with(user.id)
  #     end

  #     it "notifies all ancestors even if the author is among them" do
  #       create(:comment, parent_id: author_comment.id, commentable_id: article.id)
  #       nest_comments_authors.push(user.id).each do |id|
  #         expect(StreamNotifier).to have_received(:new).with(id).at_least(:once)
  #       end
  #     end

  #     it "does not notify self if self is among the ancestors" do
  #       me = create(:user)
  #       test_comment = create(:comment, parent_id: author_comment.id, commentable_id: article.id, user_id: me.id)
  #       create(:comment, parent_id: author_comment.id, commentable_id: article.id, user_id: me.id)
  #       allow(test_comment).to receive(:send_email_notification).and_call_original
  #       expect(StreamNotifier).not_to have_received(:new).with(me.id)
  #       expect(test_comment).not_to have_received(:send_email_notification)
  #     end
  #   end
  # end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
