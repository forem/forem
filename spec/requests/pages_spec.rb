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
      expect(response.body).to include ("Sponsorship Information")
    end
  end
end 
