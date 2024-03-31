require "rails_helper"

RSpec.describe "i8n routes" do
  let(:locale) { "fr-ca" }
  let(:i18n_route) { "/locale/#{locale}" }
  let(:user) { create(:user) }

  it "renders a user index if there is a user with the username successfully" do
    expect(get: "#{i18n_route}/#{user.username}").to route_to(
      controller: "stories",
      action: "index",
      username: user.username,
      locale: "fr-ca",
    )
  end

  it "renders a user's story successfully" do
    expect(get: "#{i18n_route}/ben/this-is-a-slug").to route_to(
      controller: "stories",
      action: "show",
      slug: "this-is-a-slug",
      username: "ben",
      locale: "fr-ca",
    )
  end

  it "renders homepage successfully" do
    expect(get: i18n_route).to route_to(
      controller: "stories",
      action: "index",
      locale: "fr-ca",
    )
  end
end
