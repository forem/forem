require "rails_helper"

RSpec.describe Events::SendNotificationsWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }

    context "for 1-day-before notifications" do
      it "sends a notification to a user signed up for an event starting in 23.5 hours" do
        event = create(:event, start_time: 23.hours.from_now + 30.minutes)
        # Using build/save to ensure callback runs normally
        signup = build(:event_signup, user: user, event: event)
        signup.save!
        # Reset the flag because save! might set it to true if time is close. Let's force it to false to test the worker.
        signup.update_columns(notified_1_day_before: false, notified_1_hour_before: false)

        expect {
          described_class.new.perform
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.user_id).to eq(user.id)
        expect(notification.notifiable_id).to eq(event.id)
        expect(notification.notifiable_type).to eq("Event")
        expect(notification.json_data["time"]).to eq("1 day")

        expect(signup.reload.notified_1_day_before).to be(true)
      end

      it "does not send a notification if already notified" do
        event = create(:event, start_time: 23.hours.from_now)
        signup = create(:event_signup, user: user, event: event)
        signup.update_columns(notified_1_day_before: true, notified_1_hour_before: false)

        expect {
          described_class.new.perform
        }.not_to change(Notification, :count)
      end

      it "does not send a 1-day notification if event starts in less than 1 hour" do
        event = create(:event, start_time: 30.minutes.from_now)
        signup = build(:event_signup, user: user, event: event)
        signup.save!
        signup.update_columns(notified_1_day_before: false, notified_1_hour_before: false)

        expect {
          described_class.new.perform
        }.to change(Notification, :count).by(1) # It should send the 1-hour one instead!

        expect(signup.reload.notified_1_day_before).to be(false)
        expect(signup.reload.notified_1_hour_before).to be(true)
      end
    end

    context "for 1-hour-before notifications" do
      it "sends a notification to a user signed up for an event starting in 30 minutes" do
        event = create(:event, start_time: 30.minutes.from_now)
        signup = build(:event_signup, user: user, event: event)
        signup.save!
        signup.update_columns(notified_1_day_before: true, notified_1_hour_before: false)

        expect {
          described_class.new.perform
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.user_id).to eq(user.id)
        expect(notification.notifiable_id).to eq(event.id)
        expect(notification.notifiable_type).to eq("Event")
        expect(notification.json_data["time"]).to eq("1 hour")

        expect(signup.reload.notified_1_hour_before).to be(true)
      end

      it "does not send a notification if already notified" do
        event = create(:event, start_time: 30.minutes.from_now)
        signup = create(:event_signup, user: user, event: event)
        signup.update_columns(notified_1_day_before: true, notified_1_hour_before: true)

        expect {
          described_class.new.perform
        }.not_to change(Notification, :count)
      end

      it "does not send if event has already started" do
        event = create(:event, start_time: 30.minutes.ago)
        signup = build(:event_signup, user: user, event: event)
        signup.save!
        signup.update_columns(notified_1_day_before: true, notified_1_hour_before: false)

        expect {
          described_class.new.perform
        }.not_to change(Notification, :count)
      end
    end
  end
end
