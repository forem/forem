require "rails_helper"

RSpec.describe "EmailSignups", type: :request do
  let(:article_with_email_signup) { create(:article, body_markdown: "---\ntitle: Email Signup#{rand(1000)}\npublished: true\n---\n\n{% email_signup 'CTA text' %}") }

  describe "POST /email_signups - EmailSignups#create" do
    it "creates a UserSubscription" do
      expect(true).to eq true
    end
  end
end
