require "rails_helper"

RSpec.describe FeedEvent do
  let(:reaction_multiplier) { FeedEvent::REACTION_SCORE_MULTIPLIER }
  let(:comment_multiplier)  { FeedEvent::COMMENT_SCORE_MULTIPLIER }
  let(:valid_categories)    { %w[impression click reaction comment extended_pageview] }

  describe "validations" do
    it { is_expected.to belong_to(:article).optional }
    it { is_expected.to validate_numericality_of(:article_id).only_integer }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to validate_numericality_of(:user_id).only_integer.allow_nil }
    it { is_expected.to define_enum_for(:category).with_values(valid_categories) }
    it { is_expected.to validate_numericality_of(:article_position).only_integer.is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:context_type).in_array(%w[home search tag email]) }
  end

  describe ".record_journey_for" do
    subject(:record_journey) { described_class.record_journey_for(user, article: article, category: category) }
    let(:article)  { create(:article) }
    let(:user)     { create(:user) }
    let(:category) { :reaction }

    context "when the user's last click was on the specified article" do
      let!(:click) { create(:feed_event, user: user, article: article, category: :click, article_position: 2, context_type: "home") }
      it "creates a new feed event with attributes copied from the click" do
        expect { record_journey }.to change(described_class, :count).by(1)
        last_event = user.feed_events.last
        expect(last_event.category).to eq("reaction")
        expect(last_event.article_id).to eq(article.id)
        expect(last_event.user_id).to eq(user.id)
        expect(last_event.context_type).to eq(click.context_type)
        expect(last_event.article_position).to eq(click.article_position)
      end
    end

    context "when there are no feed events for the specified article" do
      it "does not create a new feed event" do
        expect { record_journey }.not_to change(described_class, :count)
        expect(user.feed_events).to be_empty
      end
    end

    context "when the last click is not on the specified article" do
      let!(:click)       { create(:feed_event, user: user, article: article, category: :click) }
      let!(:other_click) { create(:feed_event, user: user, category: :click) }
      it "does not create a new feed event" do
        expect { record_journey }.not_to change(described_class, :count)
        expect(user.feed_events).to contain_exactly(click, other_click)
      end
    end

    context "when the interaction type is not one of reaction, comment, or extended_pageview" do
      let(:category) { :impression }
      let!(:click)   { create(:feed_event, user: user, article: article, category: :click) }
      it "does not create a new feed event" do
        expect { record_journey }.not_to change(described_class, :count)
        expect(user.feed_events).to contain_exactly(click)
      end
    end
  end

  describe "after_create_commit .record_field_test_event" do
    let(:goal) { AbExperiment::GoalConversionHandler::USER_CREATES_EMAIL_FEED_EVENT_GOAL }
    before do
      allow(Users::RecordFieldTestEventWorker).to receive(:perform_async)
      # Current behavior: if experiments are present the worker is enqueued regardless of event type, user, or context.
      allow(FieldTest).to receive(:config).and_return({ "experiments" => { "some_experiment" => true } })
    end

    context "when experiments config is nil" do
      before { allow(FieldTest).to receive(:config).and_return({ "experiments" => nil }) }
      it "does not record a field test event" do
        create(:feed_event, user: create(:user), category: "click", context_type: "email")
        expect(Users::RecordFieldTestEventWorker).not_to have_received(:perform_async)
      end
    end
  end

  describe "after_save .update_article_counters_and_scores" do
    let!(:article) { create(:article, feed_success_score: 0.0, feed_impressions_count: 0, feed_clicks_count: 0) }
    let!(:user1)   { create(:user) }
    let!(:user2)   { create(:user) }

    before do
      # Bypass throttling so that the update block runs immediately.
      allow(ThrottledCall).to receive(:perform).and_yield
    end

    context "when feed events exist for the article" do
      it "updates the article counters and computes the score based on distinct impression users" do
        create(:feed_event, category: "impression", article: article, user: user1, article_position: 1)
        create(:feed_event, category: "click", article: article, user: user1, article_position: 1)
        create(:feed_event, category: "reaction", article: article, user: user1, article_position: 1)
        create(:feed_event, category: "comment", article: article, user: user2, article_position: 1)
        create(:feed_event, category: "impression", article: article, user: user2, article_position: 1)

        article.reload
        # Calculation: (click (1) + reaction (reaction_multiplier) + comment (comment_multiplier)) divided by 2 distinct impression users.
        expected_score = (1 + reaction_multiplier + comment_multiplier).to_f / 2.0
        expect(article.feed_success_score).to eq(expected_score)
        expect(article.feed_impressions_count).to eq(2)
        expect(article.feed_clicks_count).to eq(1)
      end
    end

    context "when article_id is nil" do
      it "does not call update_single_article_counters" do
        # Instead of saving (which would hit the not-null constraint), call the callback method directly
        feed_event = build(:feed_event)
        # Stub the article_id to simulate a nil value
        allow(feed_event).to receive(:article_id).and_return(nil)
        expect(FeedEvent).not_to receive(:update_single_article_counters)
        feed_event.send(:update_article_counters_and_scores)
      end
    end

    context "when only impression events occur" do
      it "updates only the impressions count" do
        expect {
          create(:feed_event, category: "impression", article: article, user: user1, article_position: 1)
        }.to change { article.reload.feed_impressions_count }.from(0).to(1)
          .and not_change { article.reload.feed_success_score }
          .and not_change { article.reload.feed_clicks_count }
      end
    end

    context "when only one type of event occurs (reaction)" do
      it "sets the score based solely on the reaction multiplier" do
        create(:feed_event, category: "reaction", article: article, user: user1, article_position: 1)
        create(:feed_event, category: "impression", article: article, user: user1, article_position: 1)
        article.reload
        expect(article.feed_success_score).to eq(reaction_multiplier)
        expect(article.feed_impressions_count).to eq(1)
        expect(article.feed_clicks_count).to eq(0)
      end
    end

    context "when events from the same user occur multiple times" do
      it "counts duplicates for totals but uses distinct users for scoring" do
        create_list(:feed_event, 2, category: "impression", article: article, user: user1, article_position: 1)
        create_list(:feed_event, 4, category: "click", article: article, user: user1, article_position: 1)
        create_list(:feed_event, 3, category: "reaction", article: article, user: user2, article_position: 1)
        create_list(:feed_event, 2, category: "comment", article: article, user: user2, article_position: 1)
        create_list(:feed_event, 3, category: "extended_pageview", article: article, user: user2, article_position: 1)
        create(:feed_event, category: "impression", article: article, user: user2, article_position: 1)

        article.reload
        # Distinct impression users: user1 and user2.
        expected_score = (1 + 1 + reaction_multiplier + comment_multiplier).to_f / 2.0
        expect(article.feed_success_score).to eq(expected_score)
        expect(article.feed_clicks_count).to eq(4)
        expect(article.feed_impressions_count).to eq(3)
      end
    end
  end

  describe ".bulk_update_counters_by_article_id" do
    let!(:article1) { create(:article, feed_success_score: 0.0, feed_impressions_count: 0, feed_clicks_count: 0) }
    let!(:article2) { create(:article, feed_success_score: 0.0, feed_impressions_count: 0, feed_clicks_count: 0) }
    let!(:user1)    { create(:user) }
    let!(:user2)    { create(:user) }

    before do
      allow(ThrottledCall).to receive(:perform).and_yield
    end

    context "when events exist for the articles" do
      before do
        # Setup for article1
        create(:feed_event, category: "impression", article: article1, user: user1, article_position: 1)
        create(:feed_event, category: "impression", article: article1, user: user2, article_position: 1)
        create(:feed_event, category: "impression", article: article1, user: user2, article_position: 1)
        create(:feed_event, category: "click", article: article1, user: user1, article_position: 1)
        create(:feed_event, category: "reaction", article: article1, user: user1, article_position: 1)
        create(:feed_event, category: "comment", article: article1, user: user2, article_position: 1)
        create(:feed_event, category: "extended_pageview", article: article1, user: user2, article_position: 1)

        # Setup for article2
        create(:feed_event, category: "impression", article: article2, user: user2, article_position: 1)
        create(:feed_event, category: "click", article: article2, user: user1, article_position: 1)
        create(:feed_event, category: "reaction", article: article2, user: user2, article_position: 1)
      end

      it "updates counters and scores for multiple articles" do
        described_class.bulk_update_counters_by_article_id([article1.id, article2.id])
        article1.reload
        article2.reload

        expected_score_article1 = (1 + 1 + reaction_multiplier + comment_multiplier).to_f / 2.0
        expected_score_article2 = (1 + reaction_multiplier).to_f / 1.0

        expect(article1.feed_success_score).to eq(expected_score_article1)
        expect(article1.feed_impressions_count).to eq(3)
        expect(article1.feed_clicks_count).to eq(1)

        expect(article2.feed_success_score).to eq(expected_score_article2)
        expect(article2.feed_impressions_count).to eq(1)
        expect(article2.feed_clicks_count).to eq(1)
      end
    end

    context "when no impression events exist for the articles" do
      before do
        create(:feed_event, category: "click", article: article2, user: user1, article_position: 1)
        create(:feed_event, category: "reaction", article: article2, user: user2, article_position: 1)
        create(:feed_event, category: "comment", article: article2, user: user2, article_position: 1)
      end

      it "leaves counters as zero" do
        described_class.bulk_update_counters_by_article_id([article1.id, article2.id])
        article1.reload
        article2.reload

        expect(article1.feed_success_score).to eq(0.0)
        expect(article1.feed_impressions_count).to eq(0)
        expect(article1.feed_clicks_count).to eq(0)

        expect(article2.feed_success_score).to eq(0.0)
        expect(article2.feed_impressions_count).to eq(0)
        expect(article2.feed_clicks_count).to eq(0)
      end
    end
  end

  describe ".update_single_feed_config_counters" do
    let(:feed_config) { create(:feed_config, feed_success_score: 0.0, feed_impressions_count: 0) }
    let(:user1)       { create(:user) }
    let(:user2)       { create(:user) }

    before do
      allow(ThrottledCall).to receive(:perform).and_yield
    end

    context "when impression events exist for the feed config" do
      before do
        # Two distinct impression events
        create(:feed_event, category: "impression", feed_config: feed_config, user: user1, article_position: 1)
        create(:feed_event, category: "impression", feed_config: feed_config, user: user2, article_position: 1)
        # One click event: POWER(2.0/3, article_position - 1) with article_position 1 gives 1.
        create(:feed_event, category: "click", feed_config: feed_config, user: user1, article_position: 1)
        # One reaction event from user1: multiplier = reaction_multiplier * 2.
        create(:feed_event, category: "reaction", feed_config: feed_config, user: user1, article_position: 1)
        # One comment event from user2: multiplier = comment_multiplier * 2.
        create(:feed_event, category: "comment", feed_config: feed_config, user: user2, article_position: 1)
        # One extended pageview event from user2: multiplier = 1.
        create(:feed_event, category: "extended_pageview", feed_config: feed_config, user: user2, article_position: 1)
      end

      it "calculates and updates the feed config counters correctly" do
        # Distinct impression users: 2.
        # Calculation:
        # clicks_score = 1,
        # reactions_score = 1 * reaction_multiplier * 2,
        # comments_score = 1 * comment_multiplier * 2,
        # pageviews_score = 1.
        # Expected score = (1 + 1 + reaction_multiplier*2 + comment_multiplier*2) / 2.
        expected_score = (1 + 1 + reaction_multiplier * 2 + comment_multiplier * 2).to_f / 2.0

        described_class.update_single_feed_config_counters(feed_config.id)
        feed_config.reload

        expect(feed_config.feed_success_score).to eq(expected_score)
        expect(feed_config.feed_impressions_count).to eq(2)
      end
    end

    context "when no impression events exist for the feed config" do
      before do
        create(:feed_event, category: "click", feed_config: feed_config, user: user1, article_position: 1)
        create(:feed_event, category: "reaction", feed_config: feed_config, user: user1, article_position: 1)
      end

      it "does not update feed config counters" do
        original_score       = feed_config.feed_success_score
        original_impressions = feed_config.feed_impressions_count

        described_class.update_single_feed_config_counters(feed_config.id)
        feed_config.reload

        expect(feed_config.feed_success_score).to eq(original_score)
        expect(feed_config.feed_impressions_count).to eq(original_impressions)
      end
    end
  end

  describe "after_save .create_feed_config_offshoot" do
    let(:article)     { create(:article) }
    let(:user)        { create(:user) }
    let(:feed_config) { create(:feed_config) }

    context "when feed_config is present and category is reaction" do
      it "calls create_slightly_modified_clone! on the feed_config" do
        expect_any_instance_of(FeedConfig).to receive(:create_slightly_modified_clone!)
        create(:feed_event, feed_config: feed_config, article: article, user: user, category: "reaction")
      end
    end

    context "when feed_config is present and category is comment" do
      it "calls create_slightly_modified_clone! on the feed_config" do
        expect_any_instance_of(FeedConfig).to receive(:create_slightly_modified_clone!)
        create(:feed_event, feed_config: feed_config, article: article, user: user, category: "comment")
      end
    end

    context "when feed_config is present and category is not reaction or comment" do
      it "does not call create_slightly_modified_clone!" do
        expect_any_instance_of(FeedConfig).not_to receive(:create_slightly_modified_clone!)
        create(:feed_event, feed_config: feed_config, article: article, user: user, category: "click")
      end
    end

    context "when feed_config is nil" do
      it "does not call create_slightly_modified_clone!" do
        expect_any_instance_of(FeedConfig).not_to receive(:create_slightly_modified_clone!)
        create(:feed_event, feed_config: nil, article: article, user: user, category: "reaction")
      end
    end
  end
end
