require "rails_helper"

RSpec.describe UserSubscriptionTag, type: :liquid_tag do
  setup { Liquid::Template.register_tag("user_subscription", described_class) }

  let(:subscriber) { create(:user) }
  let(:author) { create(:user, :super_admin) } # TODO: (Alex Smith) - update roles before release
  let(:article_with_user_subscription_tag) { create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true) }

  context "when rendering" do
    it "renders default data correctly" do
      source = create(:article, user: author)
      liquid_tag_options = { source: source, user: source.user }
      cta_text = "Some sweet CTA text"
      liquid_tag = Liquid::Template.parse("{% user_subscription #{cta_text} %}", liquid_tag_options).render
      expect(liquid_tag).to include(CGI.escapeHTML(cta_text))
      expect(liquid_tag).to include(CGI.escapeHTML(author.username))
      expect(liquid_tag).to include(CGI.escapeHTML(author.profile_image_90))
    end

    it "displays signed out view by default", type: :system, js: true do
      sign_in author
      visit "/new" # Preview behaves differently - we don't load liquid tag scripts
      fill_in "article_body_markdown", with: "{% user_subscription Some sweet CTA text %}"
      page.execute_script("window.scrollTo(0, -100000)")
      find("button", text: /\APreview\z/).click

      expect(page).to have_css("#subscription-signed-in", visible: :hidden)
      expect(page).to have_css("#subscriber-apple-auth", visible: :hidden)
      expect(page).to have_css("#response-message", visible: :hidden)
      expect(page).to have_css("#subscription-signed-out", visible: :visible)
      expect(page).to have_css("img.ltag__user-subscription-tag__author-profile-image[src='#{author.profile_image_90}']")
    end
  end

  context "when signed in", type: :system, js: true do
    before do
      sign_in subscriber
      visit article_with_user_subscription_tag.path
    end

    it "shows the signed in UX" do
      expect(page).to have_css("#subscription-signed-out", visible: :hidden)
      expect(page).to have_css("#subscriber-apple-auth", visible: :hidden)
      expect(page).to have_css("#response-message", visible: :hidden)
      expect(page).to have_css("#subscription-signed-in", visible: :visible)
      expect(page).to have_css("img.ltag__user-subscription-tag__subscriber-profile-image[src='#{subscriber.profile_image_90}']")
    end

    it "asks the user to confirm their subscription" do
      expect(page).to have_css("#user-subscription-confirmation-modal", visible: :hidden)
      click_button("Subscribe", id: "subscribe-btn")
      expect(page).to have_css("#user-subscription-confirmation-modal", visible: :visible)
    end

    it "displays a sucess mesage when a subscription is created" do
      expect(page).to have_css("#subscription-signed-out", visible: :hidden)
      expect(page).to have_css("#subscriber-apple-auth", visible: :hidden)
      expect(page).to have_css("#response-message", visible: :hidden)
      expect(page).to have_css("#subscription-signed-in", visible: :visible)
      click_button("Subscribe", id: "subscribe-btn")
      click_button("Confirm subscription", id: "confirmation-btn")
      expect(page).to have_css("#subscription-signed-in", visible: :hidden)
      expect(page).to have_css("#response-message.crayons-notice--success", visible: :visible)

      within "#response-message" do
        expect(page).to have_text("You are now subscribed")
      end
    end

    it "displays errors when there's an error creating a subscription" do
      # Create a subscription so it causes an error by already being subscribed
      create(:user_subscription, subscriber_id: subscriber.id, subscriber_email: subscriber.email, author_id: article_with_user_subscription_tag.user_id, user_subscription_sourceable: article_with_user_subscription_tag)
      expect(page).to have_css("#subscription-signed-out", visible: :hidden)
      expect(page).to have_css("#subscriber-apple-auth", visible: :hidden)
      expect(page).to have_css("#response-message", visible: :hidden)
      expect(page).to have_css("#subscription-signed-in", visible: :visible)
      click_button("Subscribe", id: "subscribe-btn")
      click_button("Confirm subscription", id: "confirmation-btn")
      expect(page).to have_css("#subscription-signed-in", visible: :hidden)
      expect(page).to have_css("#response-message.crayons-notice--danger", visible: :visible)

      within "#response-message" do
        expect(page).to have_text("Subscriber has already been taken")
      end
    end

    it "tells the user they're already subscribed by default if they're already subscribed" do
      create(:user_subscription, subscriber_id: subscriber.id, subscriber_email: subscriber.email, author_id: article_with_user_subscription_tag.user_id, user_subscription_sourceable: article_with_user_subscription_tag)
      visit article_with_user_subscription_tag.path
      expect(page).to have_css("#subscription-signed-out", visible: :hidden)
      expect(page).to have_css("#subscription-signed-in", visible: :hidden)
      expect(page).to have_css("#subscriber-apple-auth", visible: :hidden)
      expect(page).to have_css("#response-message.crayons-notice--success", visible: :visible)

      within "#response-message" do
        expect(page).to have_text("You are already subscribed.")
      end
    end
  end

  context "when signed out", type: :sytem, js: true do
    before { visit article_with_user_subscription_tag.path }

    it "prompts a user to sign in when they're signed out", type: :system, js: true do
      expect(page).to have_css("#subscription-signed-in", visible: :hidden)
      expect(page).to have_css("#response-message", visible: :hidden)
      expect(page).to have_css("#subscriber-apple-auth", visible: :hidden)
      expect(page).to have_css("#subscription-signed-out", visible: :visible)
    end
  end

  # TODO: [@thepracticaldev/delightful]: re-enable this once email confirmation
  # is re-enabled and confirm it isn't flaky.
  xcontext "when a user has an Apple private relay email address", type: :system, js: true do
    it "prompts the user to update their email address" do
      allow(subscriber).to receive(:email).and_return("test@privaterelay.appleid.com")
      sign_in subscriber
      visit article_with_user_subscription_tag.path

      expect(page).to have_css("#subscription-signed-out", visible: :hidden)
      expect(page).to have_css("#subscription-signed-in", visible: :hidden)
      expect(page).to have_css("#response-message", visible: :hidden)
      expect(page).to have_css("#subscriber-apple-auth", visible: :visible)

      within "#subscriber-apple-auth" do
        expect(page).to have_button("Subscribe", disabled: true, visible: :visible)
      end
    end
  end
end
