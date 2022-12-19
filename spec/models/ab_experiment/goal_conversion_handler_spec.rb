require "rails_helper"
RSpec.describe AbExperiment::GoalConversionHandler do
  include FieldTest::Helpers

  describe ".call" do
    subject(:handler) do
      described_class.new(user: user, goal: goal, experiments: experiments, start_date: start_date)
    end

    let(:user) { create(:user) }
    let(:start_date) { 16.days.ago }
    let(:goal) { "non_sense" }
    let(:experiments) { FieldTest.config["experiments"] }

    context "with no experiments" do
      let(:experiments) { nil }

      it "gracefully handles a case where there are no tests" do
        handler.call
        expect(FieldTest::Event.all.size).to be(0)
      end
    end

    context "with experiment that started to soon for some results" do
      let(:goal) { described_class::USER_CREATES_COMMENT_GOAL }
      let(:experiment_name) { AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT }
      let(:start_date) { 8.days.from_now }

      before do
        field_test(experiment_name, participant: user)
      end

      it "registers some events but not others", :aggregate_failures do
        7.times do |n|
          create(:comment, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        # Only the comment registered; the other one would've registered had the events happened
        # after the experiment start date.
        expect(FieldTest::Event.where(name: goal).count).to eq(1)
        expect(FieldTest::Event
               .where(name: "user_creates_comment_on_at_least_four_different_days_within_a_week")
               .count).to eq(0)
      end
    end

    context "with user who is part of field test and user_publishes_post goal" do
      let(:goal) { described_class::USER_PUBLISHES_POST_GOAL }

      before do
        field_test(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT, participant: user)
      end

      it "records a conversion", :aggregate_failures do
        create(:article, :past, past_published_at: 2.days.ago, user_id: user.id)
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq(goal)
      end

      it "records weekly post publishing conversions", :aggregate_failures do
        create(:article, :past, past_published_at: 2.days.ago, user_id: user.id)
        create(:article, :past, past_published_at: 3.days.ago, user_id: user.id)
        create(:article, :past, past_published_at: 13.days.ago, user_id: user.id)

        handler.call

        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.all.pluck(:name).sort)
          .to match_array([
            goal,
            "user_publishes_post_at_least_two_times_within_two_weeks",
            "user_publishes_post_at_least_two_times_within_week",
          ].sort)
      end

      it "records a conversion when they post 4 within a week" do
        create(:article, :past, past_published_at: 25.hours.ago, user_id: user.id)
        create(:article, :past, past_published_at: 49.hours.ago, user_id: user.id)
        create(:article, :past, past_published_at: 73.hours.ago, user_id: user.id)
        create(:article, :past, past_published_at: 97.hours.ago, user_id: user.id)

        handler.call

        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.all.pluck(:name).sort)
          .to match_array([
            goal,
            "user_publishes_post_at_least_two_times_within_two_weeks",
            "user_publishes_post_at_least_two_times_within_week",
            "user_publishes_post_on_four_different_days_within_a_week",
          ].sort)
      end
    end

    context "with user who is part of field test and user_creates_comment goal" do
      let(:goal) { described_class::USER_CREATES_COMMENT_GOAL }

      before do
        field_test(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT, participant: user)
      end

      it "records a conversion", :aggregate_failures do
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq(goal)
      end

      it "records user_creates_comment_on_at_least_four_different_days_within_a_week field test conversion",
         :aggregate_failures do
        7.times do |n|
          create(:comment, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name)
          .to eq("user_creates_comment_on_at_least_four_different_days_within_a_week")
      end
    end

    context "with user who is part of field test and user_creates_pageview goal" do
      let(:goal) { described_class::USER_CREATES_PAGEVIEW_GOAL }

      before do
        field_test(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT, participant: user)
        Timecop.freeze(Time.current.utc.at_noon)
      end

      after { Timecop.return }

      it "records a field test when user views a page", :aggregate_failures do
        create(:page_view, user_id: user.id)
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to include(goal)
      end

      it "records user_views_pages_on_at_least_two_different_days_within_a_week field test conversion",
         :aggregate_failures do
        3.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to include("user_views_pages_on_at_least_two_different_days_within_a_week")
      end

      it "records user_views_pages_on_at_least_four_different_days_within_a_week field test conversion",
         :aggregate_failures do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to include("user_views_pages_on_at_least_four_different_days_within_a_week")
      end

      it "records user_views_pages_on_at_least_nine_different_days_within_two_weeks field test conversionn",
         :aggregate_failures do
        10.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to include("user_views_pages_on_at_least_nine_different_days_within_two_weeks")
      end

      it "records user_views_pages_on_at_least_twelve_different_hours_within_five_days field test conversion",
         :aggregate_failures do
        15.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end

        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to include("user_views_pages_on_at_least_twelve_different_hours_within_five_days")
      end

      it "does not record field test conversion if not qualifying" do
        2.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        expect(FieldTest::Event.pluck(:name))
          .not_to include("user_views_pages_on_at_least_twelve_different_hours_within_five_days")
      end

      it "records user_views_pages_on_at_least_three_different_hours_within_a_day field test conversionn",
         :aggregate_failures do
        3.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to eq([goal, "user_views_pages_on_at_least_three_different_hours_within_a_day"])
      end

      it "records user_views_pages_on_at_least_four_different_hours_within_a_day field test conversionn",
         :aggregate_failures do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to eq([goal, "user_views_pages_on_at_least_three_different_hours_within_a_day",
                  "user_views_pages_on_at_least_four_different_hours_within_a_day"])
      end

      it "does not record user_views_article_four_hours_in_day field test conversion for non-qualifying activity" do
        2.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end
        handler.call
        expect(FieldTest::Event.pluck(:name))
          .not_to include("user_views_pages_on_at_least_four_different_hours_within_a_day")
      end
    end

    context "with user who is part of field test and user_creates_article_reaction goal" do
      let(:goal) { described_class::USER_CREATES_ARTICLE_REACTION_GOAL }
      let(:user) { create(:user, :trusted) } # Because we want to test handling of privileged reactions

      before do
        field_test(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT, participant: user)
      end

      it "records a conversion", :aggregate_failures do
        create(:reaction, user_id: user.id)
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq(goal)
      end

      it "records a conversion when they react 4 times within a week", :aggregate_failures do
        create(:reaction, user_id: user.id, created_at: 25.hours.ago)
        create(:reaction, user_id: user.id, created_at: 49.hours.ago)
        create(:reaction, user_id: user.id, created_at: 73.hours.ago)
        create(:reaction, user_id: user.id, created_at: 97.hours.ago)
        handler.call

        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.all.pluck(:name).sort)
          .to match_array([
            goal,
            "user_creates_article_reaction_on_four_different_days_within_a_week",
          ].sort)
      end

      it "does not record the conversion when they react to non-articles or non-public reactions" do
        create(:reaction, user_id: user.id, created_at: 25.hours.ago)
        create(:reaction, user_id: user.id, created_at: 49.hours.ago)
        create(:reaction, user_id: user.id, created_at: 73.hours.ago, category: "vomit")
        create(:reaction, user_id: user.id, created_at: 97.hours.ago, reactable: create(:comment))
        create(:reaction, user_id: user.id, created_at: 121.hours.ago)

        handler.call

        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.all.pluck(:name))
          .to match_array([goal])
      end

      it "does not record the conversion when their 4 reactions are not within a week" do
        create(:reaction, user_id: user.id, created_at: 25.hours.ago)
        create(:reaction, user_id: user.id, created_at: 49.hours.ago)
        create(:reaction, user_id: user.id, created_at: 73.hours.ago)
        create(:reaction, user_id: user.id, created_at: 217.hours.ago) # 9 days ago

        handler.call

        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.all.pluck(:name))
          .to match_array([goal])
      end
    end

    context "with user who is not part of field test" do
      let(:goal) { described_class::USER_CREATES_COMMENT_GOAL }

      it "does not register a conversion" do
        handler.call
        expect(FieldTest::Event.all.size).to be(0)
      end

      it "records user_views_article_four_days_in_week field test conversion" do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        expect(FieldTest::Event.all.size).to be(0)
      end
    end
  end
end
