require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:comment) { create(:comment, user: user, commentable: article) }

  include_examples "#sync_reactions_count", :article_comment

  describe "validations" do
    subject { comment }

    describe "builtin validations" do
      it { is_expected.to belong_to(:user) }
      it { is_expected.to belong_to(:commentable).optional }
      it { is_expected.to have_many(:reactions).dependent(:destroy) }
      it { is_expected.to have_many(:mentions).dependent(:destroy) }
      it { is_expected.to have_many(:notifications).dependent(:delete_all) }
      it { is_expected.to have_many(:notification_subscriptions).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:body_markdown) }
      it { is_expected.to validate_presence_of(:positive_reactions_count) }
      it { is_expected.to validate_presence_of(:public_reactions_count) }
      it { is_expected.to validate_presence_of(:reactions_count) }
    end

    it do
      # rubocop:disable RSpec/NamedSubject
      subject.commentable = article
      subject.user = user
      expect(subject).to(
        validate_uniqueness_of(:body_markdown).scoped_to(:user_id, :ancestry, :commentable_id, :commentable_type),
      )
      # rubocop:enable RSpec/NamedSubject
    end

    it { is_expected.to validate_length_of(:body_markdown).is_at_least(1).is_at_most(25_000) }

    # rubocop:disable RSpec/NamedSubject
    describe "commentable" do
      it "is invalid if commentable is an unpublished article" do
        subject.commentable = build(:article, published: false)

        expect(subject).not_to be_valid
      end

      it "is invalid if commentable is an article and the discussion is locked" do
        subject.commentable = build(:article, :with_discussion_lock)

        expect(subject).not_to be_valid
      end

      it "is valid without a commentable" do
        subject.commentable = nil

        expect(subject).to be_valid
      end

      it "checks for commentable_id presence only if commentable_type is present" do
        subject.commentable = nil
        subject.commentable_type = "Article"

        expect(subject).not_to be_valid
      end

      it "checks for commentable_type inclusion only if commentable_id is present" do
        subject.commentable = nil
        subject.commentable_id = article.id

        expect(subject).not_to be_valid
        expect(subject.errors.messages[:commentable_type].first).to match(/not included in the list/)
      end

      it "is valid with Article commentable type" do
        subject.commentable_type = "Article"

        expect(subject).to be_valid
      end

      it "is valid with PodcastEpisode commentable type" do
        subject.commentable_type = "PodcastEpisode"

        expect(subject).to be_valid
      end

      it "is not valid with Podcast commentable type" do
        subject.commentable_type = "Podcast"

        expect(subject).not_to be_valid
      end
    end

    describe "#user_mentions_in_markdown" do
      before do
        stub_const("Comment::MAX_USER_MENTION_LIVE_AT", 1.day.ago) # Set live_at date to a time in the past
      end

      it "is valid with any number of mentions if created before MAX_USER_MENTION_LIVE_AT date" do
        # Explicitly set created_at date to a time before MAX_USER_MENTION_LIVE_AT
        subject.created_at = 3.days.ago
        subject.commentable_type = "Article"

        subject.body_markdown = "hi @#{user.username}! " * (Settings::RateLimit.mention_creation + 1)
        expect(subject).to be_valid
      end

      it "is valid with seven or fewer mentions if created after MAX_USER_MENTION_LIVE_AT date" do
        subject.commentable_type = "Article"

        subject.body_markdown = "hi @#{user.username}! " * Settings::RateLimit.mention_creation
        expect(subject).to be_valid
      end

      it "is invalid with more than seven mentions if created after MAX_USER_MENTION_LIVE_AT date" do
        subject.commentable_type = "Article"

        subject.body_markdown = "hi @#{user.username}! " * (Settings::RateLimit.mention_creation + 1)
        expect(subject).not_to be_valid
        expect(subject.errors[:base])
          .to include("You cannot mention more than #{Settings::RateLimit.mention_creation} users in a comment!")
      end
    end
    # rubocop:enable RSpec/NamedSubject

    describe "#search_id" do
      it "returns comment_ID" do
        expect(comment.search_id).to eq("comment_#{comment.id}")
      end
    end

    describe "#processed_html" do
      let(:comment) { build(:comment, user: user, commentable: article) }

      it "converts body_markdown to proper processed_html" do
        comment.body_markdown = "# hello\n\nhy hey hey"
        comment.validate!
        expect(comment.processed_html.include?("<h1>")).to be(true)
      end

      it "adds rel=nofollow to links" do
        comment.body_markdown = "this is a comment with a link: http://dev.to"
        comment.validate!
        expect(comment.processed_html.include?('rel="nofollow"')).to be(true)
      end

      it "adds a mention url if user is mentioned like @mention" do
        comment.body_markdown = "Hello @#{user.username}, you are cool."
        comment.validate!
        expect(comment.processed_html.include?("/#{user.username}")).to be(true)
        expect(comment.processed_html.include?("href")).to be(true)
        expect(comment.processed_html.include?("Hello <a")).to be(true)
      end

      it "not double wrap an already-linked mention" do
        comment.body_markdown = "Hello <a href='/#{user.username}'>@#{user.username}</a>, you are cool."
        comment.validate!
        expect(comment.processed_html.scan(/href/).count).to eq(1)
      end

      it "does not wrap email mention with username" do
        comment.body_markdown = "Hello hello@#{user.username}.com, you are cool."
        comment.validate!
        expect(comment.processed_html.include?("/#{user.username}")).to be(false)
      end

      it "only mentions users who are actual users" do
        comment.body_markdown = "Hello @hooper, you are cool."
        comment.validate!
        expect(comment.processed_html.include?("/hooper")).to be(false)
      end

      it "mentions people if it is the first word" do
        comment.body_markdown = "@#{user.username}, you are cool."
        comment.validate!
        expect(comment.processed_html.include?("/#{user.username}")).to be(true)
      end

      it "does case incentive mention recognition" do
        comment.body_markdown = "Hello @#{user.username.titleize}, you are cool."
        comment.validate!
        expect(comment.processed_html.include?("/#{user.username}")).to be(true)
        expect(comment.processed_html.include?("href")).to be(true)
        expect(comment.processed_html.include?("Hello <a")).to be(true)
      end

      # rubocop:disable RSpec/ExampleLength
      it "shortens long urls without removing formatting", :aggregate_failures do
        long_url = "https://longurl.com/#{'x' * 100}?#{'y' * 100}"
        comment.body_markdown = "Hello #{long_url}"
        comment.validate!
        expect(comment.processed_html.include?("...")).to be(true)
        expect(comment.processed_html.size < 450).to be(true)

        comment.body_markdown = "Hello this is [**#{long_url}**](#{long_url})"
        comment.validate!
        expect(comment.processed_html.include?("...</strong>")).to be(true)

        long_text = "Does not strip out text without urls #{'x' * 200}#{'y' * 200}"
        comment.body_markdown = "[**#{long_text}**](#{long_url})"
        comment.validate!
        expect(comment.processed_html.include?("...")).to be(false)

        image_url = "https://i.picsum.photos/id/126/500/500.jpg?hmac=jNnQC44a_UR01TNuazfKROio0T_HaZVg0ikfR0d_xWY"
        comment.body_markdown = "Hello ![Alt-text](#{image_url})"
        comment.validate!
        expect(comment.processed_html.include?("<img src=\"#{image_url}\"")).to be(true)
      end

      it "shortens urls for article link previews" do
        comment.body_markdown = "{% link #{URL.url(article.path)} %}"
        expect { comment.validate! }.not_to raise_error
      end

      it "adds timestamp url if commentable has video and timestamp", :aggregate_failures do
        article.video = "https://example.com"

        comment.body_markdown = "I like the part at 4:30"
        comment.validate!
        expect(comment.processed_html.include?(">4:30</a>")).to be(true)

        comment.body_markdown = "I like the part at 4:30 and 5:50"
        comment.validate!
        expect(comment.processed_html.include?(">5:50</a>")).to eq(true)

        comment.body_markdown = "I like the part at 5:30 and :55"
        comment.validate!
        expect(comment.processed_html.include?(">:55</a>")).to eq(true)

        comment.body_markdown = "I like the part at 52:30"
        comment.validate!
        expect(comment.processed_html.include?(">52:30</a>")).to eq(true)

        comment.body_markdown = "I like the part at 1:52:30 and 1:20"
        comment.validate!
        expect(comment.processed_html.include?(">1:52:30</a>")).to eq(true)
        expect(comment.processed_html.include?(">1:20</a>")).to eq(true)
      end
      # rubocop:enable RSpec/ExampleLength

      it "does not add timestamp if commentable does not have video" do
        article.video = nil

        comment.body_markdown = "I like the part at 1:52:30 and 1:20"
        comment.validate!
        expect(comment.processed_html.include?(">1:52:30</a>")).to eq(false)
      end

      it "does not add DOCTYPE and html body to processed html" do
        comment.body_markdown = "Hello https://longurl.com/#{'x' * 100}?#{'y' * 100}"
        comment.validate!
        expect(comment.processed_html).not_to include("<!DOCTYPE")
        expect(comment.processed_html).not_to include("<html><body>")
      end
    end
  end

  describe "#id_code_generated" do
    it "gets proper generated ID code" do
      expect(described_class.new(id: 1000).id_code_generated).to eq("1cc")
    end
  end

  describe "#readable_publish_date" do
    it "does not show year in readable time if not current year" do
      expect(comment.readable_publish_date).to eq(comment.created_at.strftime("%b %-e"))
    end

    it "shows year in readable time if not current year" do
      comment.created_at = 1.year.ago
      last_year = 1.year.ago.year % 100
      expect(comment.readable_publish_date.include?("'#{last_year}")).to eq(true)
    end
  end

  describe "#path" do
    it "returns the properly formed path" do
      expect(comment.path).to eq("/#{comment.user.username}/comment/#{comment.id_code_generated}")
    end
  end

  describe "#parent_or_root_article" do
    it "returns root article if no parent comment" do
      expect(comment.parent_or_root_article).to eq(comment.commentable)
    end

    it "returns root parent comment if exists" do
      child_comment = build(:comment, parent: comment)
      expect(child_comment.parent_or_root_article).to eq(comment)
    end
  end

  describe "#parent_user" do
    it "returns the root article's user if no parent comment" do
      expect(comment.parent_user).to eq(user)
    end

    it "returns the root parent comment's user if root parent comment exists" do
      child_comment_user = build(:user)
      child_comment = build(:comment, parent: comment, user: child_comment_user)
      expect(child_comment.parent_user).not_to eq(child_comment_user)
      expect(child_comment.parent_user).to eq(comment.user)
    end
  end

  describe "#title" do
    it "is no more than 80 characters" do
      expect(comment.title.length).to be <= 80
    end

    it "is allows title of greater length if passed" do
      expect(comment.title(5).length).to eq(5)
    end

    it "gets content from body_markdown" do
      comment.body_markdown = "Migas fingerstache pbr&b tofu."
      comment.validate!
      expect(comment.title).to eq("Migas fingerstache pbr&b tofu.")
    end

    it "is converted to deleted if the comment is deleted" do
      comment.deleted = true
      expect(comment.title).to eq("[deleted]")
    end

    it "does not contain the wrong encoding" do
      comment.body_markdown = "It's the best post ever. It's so great."

      comment.validate!
      expect(comment.title).not_to include("&#39;")
    end

    # NOTE: example string taken from https://github.com/threedaymonk/htmlentities
    # as this is the gem we're removing.
    it "correctly decodes HTML entities" do
      comment.body_markdown = "&eacute;lan"
      comment.validate!
      expect(comment.title).to eq("élan")
    end
  end

  describe "#custom_css" do
    it "returns nothing when no liquid tag was used" do
      expect(comment.custom_css).to be_blank
    end

    it "returns proper liquid tag classes if used" do
      text = "{% devcomment #{comment.id_code_generated} %}"
      comment.body_markdown = text
      expect(comment.custom_css).to be_present
    end
  end

  describe ".tree_for" do
    let!(:other_comment) { create(:comment, commentable: article, user: user) }
    let!(:child_comment) { create(:comment, commentable: article, parent: comment, user: user) }

    before { comment.update_column(:score, 1) }

    it "returns a full tree" do
      comments = described_class.tree_for(article)
      expect(comments).to eq(comment => { child_comment => {} }, other_comment => {})
    end

    it "returns part of the tree" do
      comments = described_class.tree_for(article, 1)
      expect(comments).to eq(comment => { child_comment => {} })
    end
  end

  context "when callbacks are triggered after create" do
    let(:comment) { build(:comment, user: user, commentable: article) }

    it "creates an id code" do
      comment.save

      expect(comment.reload.id_code).to eq(comment.id.to_s(26))
    end

    it "enqueue a worker to create the first reaction" do
      expect do
        comment.save
      end.to change(Comments::CreateFirstReactionWorker.jobs, :size).by(1)
    end

    it "enqueues a worker to calculate comment score" do
      expect do
        comment.save
      end.to change(Comments::CalculateScoreWorker.jobs, :size).by(1)
    end

    it "enqueues a worker to send email" do
      comment.save!
      child_comment_user = create(:user)
      child_comment = build(:comment, parent: comment, user: child_comment_user, commentable: article)

      expect do
        child_comment.save!
      end.to change(Comments::SendEmailNotificationWorker.jobs, :size).by(1)
    end

    it "enqueues a worker to bust comment cache" do
      expect do
        comment.save
      end.to change(Comments::BustCacheWorker.jobs, :size).by(1)
    end

    it "touches user updated_at" do
      user.updated_at = 1.month.ago
      user.save

      expect { comment.save }.to change(user, :updated_at)
    end

    it "touches user last_comment_at" do
      user.last_comment_at = 1.month.ago
      user.save

      expect { comment.save }.to change(user, :last_comment_at)
    end

    describe "slack messages" do
      let!(:user) { create(:user) }

      before do
        article
        comment
        # making sure there are no other enqueued jobs from other tests
        sidekiq_perform_enqueued_jobs(only: Slack::Messengers::Worker)
      end

      it "queues a slack message when a warned user leaves a comment" do
        user.add_role(:warned)

        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          create(:comment, user: user, commentable: article)
        end
      end

      it "does not send notification if a regular user leaves a comment" do
        sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
          create(:comment, commentable: article, user: user)
        end
      end
    end
  end

  describe "spam" do
    it "delegates spam handling to Spam::Handler.handle_comment!" do
      allow(Spam::Handler).to receive(:handle_comment!).with(comment: comment).and_call_original
      comment.save
      expect(Spam::Handler).to have_received(:handle_comment!).with(comment: comment)
    end
  end

  context "when callbacks are triggered before save" do
    context "when the post is present" do
      it "generates character count before saving" do
        comment.save
        expect(comment.markdown_character_count).to eq(comment.body_markdown.size)
      end
    end

    context "when the commentable is not present" do
      it "raises a validation error with message 'item has been deleted'", :aggregate_failures do
        comment = build(:comment, user: user, commentable: nil, commentable_type: nil)
        comment.validate
        expect(comment).not_to be_valid
        expect(comment.errors_as_sentence).to match("item has been deleted")
      end

      it "raises a validation error with commentable_type, if commentable_type is present", :aggregate_failures do
        comment = build(:comment, user: user, commentable: nil, commentable_type: "Article")
        comment.validate
        expect(comment).not_to be_valid
        expect(comment.errors_as_sentence).to match("Article has been deleted")
      end
    end
  end

  context "when callbacks are triggered after save" do
    it "updates user last comment date" do
      comment = build(:comment, commentable: article, user: user)
      expect { comment.save }.to change(user, :last_comment_at)
    end
  end

  context "when callbacks are triggered after update" do
    it "deletes the comment's notifications when deleted is set to true" do
      create(:notification, notifiable: comment, user: user)
      sidekiq_perform_enqueued_jobs do
        comment.update(deleted: true)
      end
      expect(comment.notifications).to be_empty
    end

    it "deletes the comment's notifications when hidden_by_commentable_user is set to true" do
      create(:notification, notifiable: comment, user: user)
      sidekiq_perform_enqueued_jobs do
        comment.update(hidden_by_commentable_user: true)
      end
      expect(comment.notifications).to be_empty
    end

    it "updates the notifications of the descendants with [deleted]" do
      comment = create(:comment, commentable: article)
      child_comment = create(:comment, parent: comment, commentable: article, user: user)
      create(:notification, notifiable: child_comment, user: user)
      sidekiq_perform_enqueued_jobs do
        comment.update(deleted: true)
      end
      notification = child_comment.notifications.first
      expect(notification.json_data["comment"]["ancestors"][0]["title"]).to eq("[deleted]")
    end
  end

  context "when callbacks are triggered after destroy" do
    let!(:comment) { create(:comment, user: user, commentable: article) }

    it "updates user's last_comment_at" do
      comment = create(:comment, user: user)
      expect { comment.destroy }.to change(user, :last_comment_at)
    end

    it "busts the comment cache" do
      sidekiq_assert_enqueued_with(job: Comments::BustCacheWorker, args: [comment.id]) do
        comment.destroy
      end
    end
  end

  describe "#root_exists?" do
    let(:root_comment) { create(:comment) }
    let(:comment) { create(:comment, ancestry: root_comment.id) }

    it "returns true if root is present" do
      expect(comment.root_exists?).to eq(true)
    end

    it "returns false if root has been deleted" do
      root_comment.destroy
      expect(comment.reload.root_exists?).to eq(false)
    end
  end
end
