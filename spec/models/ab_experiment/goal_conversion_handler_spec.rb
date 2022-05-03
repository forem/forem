require "rails_helper"
RSpec.describe AbExperiment::GoalConversionHandler do
  include FieldTest::Helpers

  describe ".call" do
    subject(:handler) { described_class.new(user: user, goal: goal, experiments: experiments) }

    let(:user) { create(:user) }
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
      # NOTE: We're choosing a future date as a logic short-cut for comment tests
      let(:experiments) { { experiment_name => { "start_date" => 8.days.from_now } } }

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

      it "records user_creates_comment_on_at_least_four_different_days_within_a_week field test conversion", :aggregate_failures do
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
      end

      it "records user_views_pages_on_at_least_four_different_days_within_a_week field test conversion", :aggregate_failures do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to include("user_views_pages_on_at_least_four_different_days_within_a_week")
      end

      it "records user_views_pages_on_at_least_nine_different_days_within_two_weeks field test conversionn", :aggregate_failures do
        10.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to include("user_views_pages_on_at_least_nine_different_days_within_two_weeks")
      end

      it "records user_views_pages_on_at_least_twelve_different_hours_within_five_days field test conversion", :aggregate_failures do
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
        expect(FieldTest::Event.all.size).to be(0)
      end

      it "records user_views_pages_on_at_least_four_different_hours_within_a_day field test conversionn", :aggregate_failures do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end
        handler.call
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name))
          .to include("user_views_pages_on_at_least_four_different_hours_within_a_day")
      end

      it "does not record user_views_article_four_hours_in_day field test conversion for non-qualifying activity" do
        2.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end
        handler.call
        expect(FieldTest::Event.all.size).to be(0)
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
