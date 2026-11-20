require "rails_helper"

RSpec.describe "Badges" do
  let(:user) { create(:user) }

  describe "GET /badges" do
    let!(:badges) { create_list(:badge, 3) }

    context "when logged in" do
      before { sign_in user }

      it "shows all the badges" do
        get "/badges"
        expect(response.body).to include "Badges"
        badges.each do |badge|
          expect(response.body).to include CGI.escapeHTML(badge.badge_image_url)
          expect(response.body).to match(%r{<template id="badge-#{badge.id}">.*?</template>}m)
        end
        card_images = response.parsed_body.css(
          ".badges-page .sticker-book .badge-container > .badge-image-container > .badge-image",
        )
        modal_images = response.parsed_body.css(".badge_details > .badge-image-container > .badge-image")
        expect(card_images.size).to eq(badges.size)
        expect(modal_images.size).to eq(badges.size)
      end
    end

    context "when logged out" do
      it "shows all the badges" do
        get "/badges"
        expect(response.body).to include "Badges"
        badges.each do |badge|
          expect(response.body).to include CGI.escapeHTML(badge.badge_image_url)
          expect(response.body).to match(%r{<template id="badge-#{badge.id}">.*?</template>}m)
        end
      end

      it "gives each badge an anchor so Badge#path lands on it" do
        get "/badges"
        badges.each do |badge|
          expect(response.body).to include(%(id="#{badge.slug}"))
        end
      end
    end
  end

  describe "GET /badge/:slug" do
    it "redirects to the badge on the badges page" do
      create(:badge, slug: "beloved-comment")

      get "/badge/beloved-comment"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/badges#beloved-comment")
    end
  end
end
