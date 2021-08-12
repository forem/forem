require "rails_helper"
RSpec.describe "rendering sponsor's organization images", type: :view do
  context "when rendering sponsor's logo" do
    let(:profile_image_url) do
      "https://images.unsplash.com/photo-1627397672342-916825af27f8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxfDB8MXxyYW5kb218MHx8fHx8fHx8MTYyODc3NjE1OQ&ixlib=rb-1.2.1&q=80&w=1080"
    end
    let(:nav_image_url) do
      "https://images.unsplash.com/photo-1626553550517-4eeebf498d2a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxfDB8MXxyYW5kb218MHx8fHx8fHx8MTYyODc3NjI4OQ&ixlib=rb-1.2.1&q=80&w=1080"
    end
    let(:dark_nav_image_url) do
      "https://images.unsplash.com/photo-1628159972444-4c3baaa0f6aa?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxfDB8MXxyYW5kb218MHx8fHx8fHx8MTYyODc4NjMwMA&ixlib=rb-1.2.1&q=80&w=1080"
    end

    let(:org) { create(:organization) }
    let(:sponsorship) { create(:sponsorship, level: :gold, organization: org, expires_at: 1.day.from_now) }

    it "renders logo set for light/dark themes when they are set" do
      org.dark_nav_image = dark_nav_image_url
      org.nav_image = nav_image_url
      render "pages/sponsor_image", sponsor: org
      expect(rendered).to have_css "img", text: org.nav_image_url
      expect(rendered).to have_css "img", text: org.dark_nav_image_url
    end

    it "renders profile image when logos are not set" do
      org.profile_image = profile_image_url
      render "pages/sponsor_image", sponsor: org
      expect(rendered).to have_css "img", text: org.profile_image_url
    end
  end
end
