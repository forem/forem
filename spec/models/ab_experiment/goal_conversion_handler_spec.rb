require "rails_helper"
RSpec.describe AbExperiment::GoalConversionHandler do
  include FieldTest::Helpers

  describe ".call" do
    subject(:handler) do
      described_class.new(user: user, goal: goal, experiments: experiments, start_date: start_date)
    end

    let(:user) { create(:user, :without_profile, profile_image: nil) }
    let(:article) { create(:article, user: user, with_tags: false, with_main_image: false) }
    let(:start_date) { 16.days.ago }
    let(:goal) { "non_sense" }
    let(:experiments) { FieldTest.config["experiments"] }

    def create_page_view(created_at: Time.current)
      create(:page_view, user: user, article: nil, referrer: nil, created_at: created_at)
    end

    def call_and_event_names
      FieldTest::Event.delete_all
      handler.call
      FieldTest::Event.pluck(:name)
    end

    context "with no experiments" do
      let(:user) { build_stubbed(:user) }
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
        4.times do |n|
          create(:comment, commentable: article, user: user, created_at: n.days.ago)
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

    context "with user who is part of field test and user_creates_comment goal" do
      let(:goal) { described_class::USER_CREATES_COMMENT_GOAL }

      before do
        field_test(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT, participant: user)
      end

      it "records a base conversion and records the 4-day conversion once threshold is met", :aggregate_failures do
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name)).to eq([goal])

        4.times do |n|
          create(:comment, commentable: article, user: user, created_at: n.days.ago)
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

      it "records day-based pageview conversions as multi-day thresholds are reached", :aggregate_failures do
        create_page_view(created_at: 0.days.ago)
        expect(call_and_event_names).to eq([goal])
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)

        create_page_view(created_at: 1.day.ago)
        expect(call_and_event_names)
          .to include("user_views_pages_on_at_least_two_different_days_within_a_week")
          .and exclude(
            "user_views_pages_on_at_least_four_different_days_within_a_week",
            "user_views_pages_on_at_least_nine_different_days_within_two_weeks",
            "user_views_pages_on_at_least_twelve_different_hours_within_five_days",
          )

        (2..3).each { |n| create_page_view(created_at: n.days.ago) }
        expect(call_and_event_names)
          .to include("user_views_pages_on_at_least_four_different_days_within_a_week")
          .and exclude("user_views_pages_on_at_least_nine_different_days_within_two_weeks")

        (4..8).each { |n| create_page_view(created_at: n.days.ago) }
        expect(call_and_event_names)
          .to include("user_views_pages_on_at_least_nine_different_days_within_two_weeks")
      end

      it "records hour-based pageview conversions only when hourly thresholds are reached", :aggregate_failures do
        2.times { |n| create_page_view(created_at: n.hours.ago) }
        expect(call_and_event_names)
          .to eq([goal])
          .and exclude(
            "user_views_pages_on_at_least_four_different_hours_within_a_day",
            "user_views_pages_on_at_least_twelve_different_hours_within_five_days",
          )

        create_page_view(created_at: 2.hours.ago)
        expect(call_and_event_names)
          .to eq([goal, "user_views_pages_on_at_least_three_different_hours_within_a_day"])
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)

        create_page_view(created_at: 3.hours.ago)
        expect(call_and_event_names)
          .to eq([goal, "user_views_pages_on_at_least_three_different_hours_within_a_day",
                  "user_views_pages_on_at_least_four_different_hours_within_a_day"])
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)

        (4..11).each { |n| create_page_view(created_at: n.hours.ago) }
        expect(call_and_event_names)
          .to include("user_views_pages_on_at_least_twelve_different_hours_within_five_days")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
      end
    end

    context "with user who is part of field test and user_creates_article_reaction goal" do
      let(:goal) { described_class::USER_CREATES_ARTICLE_REACTION_GOAL }
      let(:user) { create(:user, :trusted, :without_profile, profile_image: nil) }

      before do
        field_test(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT, participant: user)
      end

      it "records a base conversion and only converts the 4-day goal for 4 public article reactions within a week",
         :aggregate_failures do
        create(:reaction, reactable: article, user: user, category: "like", created_at: 25.hours.ago)
        create(:reaction, reactable: article, user: user, category: "unicorn", created_at: 49.hours.ago)
        create(:reaction, reactable: article, user: user, category: "exploding_head", created_at: 73.hours.ago)
        create(:reaction, reactable: article, user: user, category: "raised_hands", created_at: 217.hours.ago)

        expect(call_and_event_names).to contain_exactly(goal)
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)

        comment = create(:comment, commentable: article, user: user)
        create(:reaction, reactable: article, user: user, category: "vomit", created_at: 97.hours.ago)
        create(:reaction, reactable: comment, user: user, category: "like", created_at: 121.hours.ago)

        expect(call_and_event_names).to contain_exactly(goal)

        create(:reaction, reactable: article, user: user, category: "fire", created_at: 97.hours.ago)

        expect(call_and_event_names.sort)
          .to match_array([
            goal,
            "user_creates_article_reaction_on_four_different_days_within_a_week",
          ].sort)
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
      end
    end

    context "with user who is not part of field test" do
      let(:goal) { described_class::USER_CREATES_COMMENT_GOAL }

      it "does not register a conversion even with qualifying activity", :aggregate_failures do
        handler.call
        expect(FieldTest::Event.all.size).to be(0)

        4.times { |n| create_page_view(created_at: n.days.ago) }
        described_class.call(
          user: user,
          goal: described_class::USER_CREATES_PAGEVIEW_GOAL,
          experiments: experiments,
          start_date: start_date,
        )
        expect(FieldTest::Event.all.size).to be(0)
      end
    end

    context "with user who is part of field test and user_creates_email_feed_event goal" do
      let(:goal) { described_class::USER_CREATES_EMAIL_FEED_EVENT_GOAL }

      before do
        field_test(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT, participant: user)
      end

      it "records a conversio for click", :aggregate_failures do
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq(goal)
        expect(FieldTest::Event.all.size).to be(1)
      end
    end
  end
end
