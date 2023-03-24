require "rails_helper"

RSpec.describe "all routes" do
  let(:podcast)     { create(:podcast) }
  let(:user)        { create(:user) }

  describe "#root_url" do
    it "matches URL.url('/')" do
      expect(root_url).to eq(URL.url("/"))
    end
  end

  describe "/listings" do
    subject(:a_request) { { get: "/listings" } }

    context "when enabled" do
      before { allow(Listing).to receive(:feature_enabled?).and_return(true) }

      it { is_expected.to route_to(controller: "listings", action: "index", locale: nil) }
    end

    context "when disabled" do
      before { allow(Listing).to receive(:feature_enabled?).and_return(false) }

      it { is_expected.not_to route_to(controller: "listings", action: "index", locale: nil) }
    end
  end

  it "renders a podcast index if there is a podcast with the slug successfully" do
    expect(get: "/#{podcast.slug}").to route_to(
      controller: "stories",
      action: "index",
      username: podcast.slug,
      locale: nil, # default locale
    )
  end

  it "renders a user index if there is a user with the username successfully" do
    expect(get: "/#{user.username}").to route_to(
      controller: "stories",
      action: "index",
      username: user.username,
      locale: nil, # default locale
    )
  end

  it "renders a user's story successfully" do
    expect(get: "/ben/this-is-a-slug").to route_to(
      controller: "stories",
      action: "show",
      slug: "this-is-a-slug",
      username: "ben",
      locale: nil, # default locale
    )
  end

  context "when redirected routes" do
    include RSpec::Rails::RequestExampleGroup

    it "redirects /settings/integrations to /settings/extensions" do
      get user_settings_path(:integrations)

      expect(response).to redirect_to(user_settings_path(:extensions))
    end

    it "redirects /settings/misc to /settings" do
      get user_settings_path(:misc)

      expect(response).to redirect_to(user_settings_path)
    end

    it "redirects /settings/publishing-from-rss to /settings/extensions" do
      get user_settings_path("publishing-from-rss")

      expect(response).to redirect_to(user_settings_path(:extensions))
    end

    it "redirects /settings/ux to /settings/customization" do
      get user_settings_path(:ux)

      expect(response).to redirect_to(user_settings_path(:customization))
    end
  end
end
