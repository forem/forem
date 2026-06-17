require "rails_helper"

RSpec.describe "EventSignups", type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event, start_time: 2.days.from_now) }

  describe "POST /events/:event_name_slug/:event_variation_slug/signup" do
    context "when logged out" do
      it "redirects to the sign up path" do
        post event_signup_path(event.event_name_slug, event.event_variation_slug)
        expect(response).to redirect_to(new_magic_link_path)
      end
    end

    context "when logged in" do
      before { login_as(user) }

      it "creates an event signup and redirects back to the event show page" do
        expect {
          post event_signup_path(event.event_name_slug, event.event_variation_slug)
        }.to change(EventSignup, :count).by(1)

        expect(response).to redirect_to(event_path(event.event_name_slug, event.event_variation_slug))
        expect(flash[:notice]).to eq("You've successfully signed up for this event!")
      end

      it "does not duplicate signups if already signed up" do
        create(:event_signup, user: user, event: event)

        expect {
          post event_signup_path(event.event_name_slug, event.event_variation_slug)
        }.not_to change(EventSignup, :count)

        expect(response).to redirect_to(event_path(event.event_name_slug, event.event_variation_slug))
      end

      it "handles concurrent signups gracefully and treats it as success" do
        allow_any_instance_of(EventSignup).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique.new("duplicate key"))

        expect {
          post event_signup_path(event.event_name_slug, event.event_variation_slug)
        }.not_to change(EventSignup, :count)

        expect(response).to redirect_to(event_path(event.event_name_slug, event.event_variation_slug))
        expect(flash[:notice]).to eq("You've successfully signed up for this event!")
      end

      it "handles validation-level concurrent signups gracefully and treats it as success" do
        signup = build(:event_signup, user: user, event: event)
        signup.errors.add(:user_id, :taken, message: "has already signed up")
        allow_any_instance_of(EventSignup).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(signup))

        expect {
          post event_signup_path(event.event_name_slug, event.event_variation_slug)
        }.not_to change(EventSignup, :count)

        expect(response).to redirect_to(event_path(event.event_name_slug, event.event_variation_slug))
        expect(flash[:notice]).to eq("You've successfully signed up for this event!")
      end
    end
  end

  describe "DELETE /events/:event_name_slug/:event_variation_slug/signup" do
    context "when logged out" do
      it "redirects to the login path" do
        delete event_signup_path(event.event_name_slug, event.event_variation_slug)
        expect(response).to redirect_to(new_magic_link_path)
      end
    end

    context "when logged in" do
      before { login_as(user) }

      it "deletes the event signup and redirects back" do
        create(:event_signup, user: user, event: event)

        expect {
          delete event_signup_path(event.event_name_slug, event.event_variation_slug)
        }.to change(EventSignup, :count).by(-1)

        expect(response).to redirect_to(event_path(event.event_name_slug, event.event_variation_slug))
        expect(flash[:notice]).to eq("You've removed your interest in this event.")
      end

      it "does not fail if the signup does not exist" do
        expect {
          delete event_signup_path(event.event_name_slug, event.event_variation_slug)
        }.not_to change(EventSignup, :count)

        expect(response).to redirect_to(event_path(event.event_name_slug, event.event_variation_slug))
      end
    end
  end
end
