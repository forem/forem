require "rails_helper"

RSpec.describe UserSubscriptionTag, type: :liquid_tag, js: true do
  setup { Liquid::Template.register_tag("user_subscription", described_class) }

  let(:subscriber) { create(:user) }
  let(:author) { create(:user, :super_admin) }
  let(:source) { create(:article, user: author) }
  let(:liquid_tag_options) { { source: source, user: source.user } }

  def generate_user_subscription_tag(cta_text = nil)
    Liquid::Template.parse("{% user_subscription #{cta_text} %}", liquid_tag_options)
  end

  context "when rendering" do
    it "renders default data correctly" do
      cta_text = "Some sweet CTA text"
      liquid = generate_user_subscription_tag(cta_text)
      expect(liquid.render).to include(CGI.escapeHTML(cta_text))
      expect(liquid.render).to include(CGI.escapeHTML(author.username))
      expect(liquid.render).to include(CGI.escapeHTML(author.profile_image_90))
    end

    it "displays signed out view by default" do
    end
  end

  context "when signed in" do
    it "goes through the subscribe flow" do
    end
  end

  context "when signed out" do
    it "prompts a user to sign in when they're signed out" do
    end
  end

  context "when there's an error subscribing" do
    it "shows the error flow when there's an error creating a subscription" do
    end
  end

  context "when a user has an Apple private relay email address" do
    it "prompts the user to update their email address" do
    end
  end
end
