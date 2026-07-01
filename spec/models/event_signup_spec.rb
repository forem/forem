require "rails_helper"

RSpec.describe EventSignup, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:event) }
  end

  describe "validations" do
    subject { build(:event_signup) }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:event_id) }

    it "requires uniqueness of user_id scoped to event_id" do
      user = create(:user)
      event = create(:event)
      create(:event_signup, user: user, event: event)
      duplicate = build(:event_signup, user: user, event: event)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already signed up for this event")
    end
  end

  describe "callbacks" do
    describe "initialize_notification_flags" do
      let(:user) { create(:user) }

      it "sets flags to false if event starts in more than 24 hours" do
        event = create(:event, start_time: 30.hours.from_now)
        signup = create(:event_signup, user: user, event: event)
        expect(signup.notified_1_day_before).to be(false)
        expect(signup.notified_1_hour_before).to be(false)
      end

      it "sets notified_1_day_before to true if event starts in less than 23 hours but more than 1 hour" do
        event = create(:event, start_time: 12.hours.from_now)
        signup = create(:event_signup, user: user, event: event)
        expect(signup.notified_1_day_before).to be(true)
        expect(signup.notified_1_hour_before).to be(false)
      end

      it "sets notified_1_day_before to true and notified_1_hour_before to false if event starts in less than 1 hour" do
        event = create(:event, start_time: 30.minutes.from_now)
        signup = create(:event_signup, user: user, event: event)
        expect(signup.notified_1_day_before).to be(true)
        expect(signup.notified_1_hour_before).to be(false)
      end

      it "sets both flags to true if event has already started" do
        event = create(:event, start_time: 5.minutes.ago)
        signup = create(:event_signup, user: user, event: event)
        expect(signup.notified_1_day_before).to be(true)
        expect(signup.notified_1_hour_before).to be(true)
      end
    end

    describe "auto_follow_challenge_tags" do
      let(:user) { create(:user) }
      let(:tag1) { create(:tag, name: "devchallenge") }
      let(:tag2) { create(:tag, name: "writeathon") }

      context "when the event is a challenge" do
        it "auto-follows the tag configured in auto_follow_tag_names" do
          event = create(:event, type_of: :challenge, data: { "auto_follow_tag_names" => "#{tag1.name}, #{tag2.name}" })
          
          expect {
            create(:event_signup, user: user, event: event)
          }.to change { user.reload.following_tags_count }.by(2)

          expect(user.following?(tag1)).to be(true)
          expect(user.following?(tag2)).to be(true)
        end

        it "falls back to following the event's first tag if auto_follow_tag_names is empty" do
          event = create(:event, type_of: :challenge)
          event.tags << tag1

          expect {
            create(:event_signup, user: user, event: event)
          }.to change { user.reload.following_tags_count }.by(1)

          expect(user.following?(tag1)).to be(true)
        end

        it "handles non-existent tags gracefully" do
          event = create(:event, type_of: :challenge, data: { "auto_follow_tag_names" => "nonexistent_tag" })

          expect {
            create(:event_signup, user: user, event: event)
          }.not_to change { user.following_tags_count }
        end
      end

      context "when the event is not a challenge" do
        it "does not auto-follow any tags even if configured" do
          event = create(:event, type_of: :live_stream, data: { "auto_follow_tag_names" => "#{tag1.name}" })
          event.tags << tag2

          expect {
            create(:event_signup, user: user, event: event)
          }.not_to change { user.following_tags_count }

          expect(user.following?(tag1)).to be(false)
          expect(user.following?(tag2)).to be(false)
        end
      end
    end
  end
end
