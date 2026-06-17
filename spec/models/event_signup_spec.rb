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

      it "sets notified_1_day_before to true if event starts in less than 24 hours but more than 1 hour" do
        event = create(:event, start_time: 12.hours.from_now)
        signup = create(:event_signup, user: user, event: event)
        expect(signup.notified_1_day_before).to be(true)
        expect(signup.notified_1_hour_before).to be(false)
      end

      it "sets both flags to true if event starts in less than 1 hour" do
        event = create(:event, start_time: 30.minutes.from_now)
        signup = create(:event_signup, user: user, event: event)
        expect(signup.notified_1_day_before).to be(true)
        expect(signup.notified_1_hour_before).to be(true)
      end
    end
  end
end
