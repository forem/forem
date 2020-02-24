require "rails_helper"

RSpec.describe Users::RecordFieldTestEventWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1
  include FieldTest::Helpers

  describe "#perform" do
    let(:worker) { subject }
    let_it_be(:user) { create(:user) }

    context "with user who is part of field test" do
      before do
        field_test(:user_home_feed, participant: user)
      end

      it "records makes_reaction field test conversion" do
        worker.perform(user.id, "user_home_feed", "makes_reaction")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq("makes_reaction")
      end

      it "records makes_comment field test conversion" do
        worker.perform(user.id, "user_home_feed", "makes_comment")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq("makes_comment")
      end

      it "records makes_article_pageview_four_days_in_week field test conversion if qualifies" do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.day.ago)
        end
        worker.perform(user.id, "user_home_feed", "makes_article_pageview_four_days_in_week")
        expect(FieldTest::Event.last.field_test_membership.participant_id).to eq(user.id.to_s)
        expect(FieldTest::Event.last.name).to eq("makes_article_pageview_four_days_in_week")
      end

      it "does not record makes_article_pageview_four_days_in_week field test conversion if not qualifying" do
        2.times do |n|
          create(:page_view, user_id: user.id, created_at: n.day.ago)
        end
        worker.perform(user.id, "user_home_feed", "makes_article_pageview_four_days_in_week")
        expect(FieldTest::Event.all.size).to be(0)
      end
    end

    context "with user who is not part of field test" do
      it "records makes_reaction field test conversion" do
        worker.perform(user.id, "user_home_feed", "makes_reaction")
        expect(FieldTest::Event.all.size).to be(0)
      end

      it "records makes_comment field test conversion" do
        worker.perform(user.id, "user_home_feed", "makes_comment")
        expect(FieldTest::Event.all.size).to be(0)
      end

      it "records makes_article_pageview_four_days_in_week field test conversion if qualifies" do
        7.times do |n|
          create(:page_view, user_id: user.id, created_at: n.day.ago)
        end
        expect(FieldTest::Event.all.size).to be(0)
      end
    end
  end
end
