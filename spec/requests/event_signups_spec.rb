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

  describe "AJAX signup and status check" do
    let(:challenge_event) { create(:event, type_of: :challenge, start_time: 2.days.from_now) }

    describe "GET /events/:event_name_slug/:event_variation_slug/signup_status" do
      context "when logged out" do
        it "returns status false and correct button text for standard event" do
          get event_signup_status_path(event.event_name_slug, event.event_variation_slug)
          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json["signed_up"]).to be(false)
          expect(json["button_text"]).to eq("I'm Interested")
        end

        it "returns status false and correct button text for challenge" do
          get event_signup_status_path(challenge_event.event_name_slug, challenge_event.event_variation_slug)
          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json["signed_up"]).to be(false)
          expect(json["button_text"]).to eq("Sign Up")
        end
      end

      context "when logged in" do
        before { login_as(user) }

        it "returns status true when signed up" do
          create(:event_signup, user: user, event: event)
          get event_signup_status_path(event.event_name_slug, event.event_variation_slug)
          json = response.parsed_body
          expect(json["signed_up"]).to be(true)
          expect(json["button_text"]).to eq("Interested")
        end

        it "returns status true when signed up for challenge" do
          create(:event_signup, user: user, event: challenge_event)
          get event_signup_status_path(challenge_event.event_name_slug, challenge_event.event_variation_slug)
          json = response.parsed_body
          expect(json["signed_up"]).to be(true)
          expect(json["button_text"]).to eq("Signed Up")
        end
      end
    end

    describe "POST /events/:event_name_slug/:event_variation_slug/signup.json" do
      before { login_as(user) }

      it "creates signup and returns JSON response for standard event" do
        expect {
          post event_signup_path(event.event_name_slug, event.event_variation_slug, format: :json)
        }.to change(EventSignup, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["signed_up"]).to be(true)
        expect(json["button_text"]).to eq("Interested")
      end

      it "creates signup and returns JSON response for challenge" do
        expect {
          post event_signup_path(challenge_event.event_name_slug, challenge_event.event_variation_slug, format: :json)
        }.to change(EventSignup, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["signed_up"]).to be(true)
        expect(json["button_text"]).to eq("Signed Up")
      end
    end

    describe "DELETE /events/:event_name_slug/:event_variation_slug/signup.json" do
      before { login_as(user) }

      it "deletes signup and returns JSON response for standard event" do
        create(:event_signup, user: user, event: event)
        expect {
          delete event_signup_path(event.event_name_slug, event.event_variation_slug, format: :json)
        }.to change(EventSignup, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["signed_up"]).to be(false)
        expect(json["button_text"]).to eq("I'm Interested")
      end
    end
  end
end
