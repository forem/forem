require "rails_helper"

RSpec.describe Users::RecordFieldTestEventWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1
  include FieldTest::Helpers

  describe "#perform" do
    let(:worker) { subject }

    let(:user) { create(:user) }

    context "with user who is part of field test" do
      before do
        field_test(:feed_top_articles_query, participant: user)
      end

      it "records user_creates_reaction field test conversion" do
        worker.perform(user.id, "user_creates_reaction")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq("user_creates_reaction")
      end

      it "records user_creates_comment field test conversion" do
        worker.perform(user.id, "user_creates_comment")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq("user_creates_comment")
      end

      it "records user_creates_comment_four_days_in_week field test conversion if qualifies" do
        7.times do |n|
          create(:comment, user_id: user.id, created_at: n.days.ago)
        end
        worker.perform(user.id, "user_creates_comment")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq("user_creates_comment_four_days_in_week")
      end

      it "records user_views_article_four_days_in_week field test conversion if qualifies" do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        worker.perform(user.id, "user_creates_pageview")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name)).to include("user_views_article_four_days_in_week")
      end

      it "records user_views_article_nine_days_in_two_week field test conversion if qualifies" do
        10.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        worker.perform(user.id, "user_creates_pageview")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name)).to include("user_views_article_nine_days_in_two_week")
      end

      it "records user_views_article_twelve_hours_in_five_days field test conversion if qualifies" do
        15.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end

        worker.perform(user.id, "user_creates_pageview")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name)).to include("user_views_article_twelve_hours_in_five_days")
      end

      it "does not record user_views_article_four_days_in_week field test conversion if not qualifying" do
        2.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        worker.perform(user.id, "user_creates_pageview")
        expect(FieldTest::Event.all.size).to be(0)
      end

      it "records user_views_article_four_hours_in_day field test conversion if qualifies" do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end
        worker.perform(user.id, "user_creates_pageview")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.pluck(:name)).to include("user_views_article_four_hours_in_day")
      end

      it "does not record user_views_article_four_hours_in_day field test conversion if not qualifying" do
        2.times do |n|
          create(:page_view, user_id: user.id, created_at: n.hours.ago)
        end
        worker.perform(user.id, "user_creates_pageview")
        expect(FieldTest::Event.all.size).to be(0)
      end
    end

    context "with user who is not part of field test" do
      it "records user_creates_reaction field test conversion" do
        worker.perform(user.id, "user_creates_reaction")
        expect(FieldTest::Event.all.size).to be(0)
      end

      it "records user_creates_comment field test conversion" do
        worker.perform(user.id, "user_creates_comment")
        expect(FieldTest::Event.all.size).to be(0)
      end

      it "records user_views_article_four_days_in_week field test conversion if qualifies" do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.days.ago)
        end
        expect(FieldTest::Event.all.size).to be(0)
      end
    end

    context "without a user" do
      it "does not raise an error" do
        expect do
          worker.perform(user.id + 1000, "user_creates_reaction")
        end.not_to raise_error
      end
    end
  end
end
