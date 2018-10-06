require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /about" do
    it "has proper headline" do
      get "/about"
      expect(response.body).to include("About dev.to")
    end
  end

  describe "GET /privacy" do
    it "has proper headline" do
      get "/privacy"
      expect(response.body).to include("Privacy Policy")
    end
  end

  describe "GET /terms" do
    it "has proper headline" do
      get "/terms"
      expect(response.body).to include("Web Site Terms and Conditions of Use")
    end
  end

  describe "GET /security" do
    it "has proper headline" do
      get "/security"
      expect(response.body).to include("Reporting Vulnerabilities to dev.to")
    end
  end

  describe "GET /code-of-conduct" do
    it "has proper headline" do
      get "/code-of-conduct"
      expect(response.body).to include("Code of Conduct")
    end
  end

  describe "GET /rly" do
    it "has proper headline" do
      get "/rly"
      expect(response.body).to include("O RLY Cover Generator")
    end
  end

  describe "GET /sponsorship-info" do
    it "has proper headline" do
      get "/sponsorship-info"
      expect(response.body).to include("Sponsorship Information")
    end
  end

  describe "GET /membership" do
    it "has proper headline" do
      get "/membership"
      expect(response.body).to include("Sustaining Membership")
    end
  end

  describe "GET /welcome" do
    it "has proper headline" do
      get "/welcome"

      expect(response.body).to include("You are being <a")
    end
  end

  describe "GET /live" do
    let(:user) { create(:user) }

    context "when nothing is live" do
      it "shows the correct message" do
        get "/live"
        expect(response.body).to include("Nothing is live right now")
      end
    end

    context "when live is starting soon" do
      before do
        Sail::Setting.create(name: :live_starting_soon, value: "true", cast_type: :boolean)
        get "/live"
      end

      after do
        Sail::Setting.create(name: :live_starting_soon, value: "false", cast_type: :boolean)
      end

      it "shows the correct message" do
        expect(response.body).to include("Our event is starting soon")
      end
    end

    context "when live is live" do
      before do
        Sail::Setting.create(name: :live_is_live, value: "true", cast_type: :boolean)
        create(:chat_channel, :workshop)
      end

      after do
        Sail::Setting.create(name: :live_is_live, value: "false", cast_type: :boolean)
      end

      it "shows a sign in page for logged out users" do
        get "/live"
        expect(response.body).to include("Sign In or Create Your Account")
      end

      it "shows the video for logged in users" do
        login_as user
        get "/live"
        expect(response.body).to include("<iframe class=\"live-video\"")
      end

      it "shows the chat for logged in users" do
        login_as user
        get "/live"
        expect(response.body).to include("<div id=\"chat\"")
      end
    end
  end
end
