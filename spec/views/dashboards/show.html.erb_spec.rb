require "rails_helper"

RSpec.describe "dashboards/show.html.erb", type: :view do
  before do
    stub_template "dashboards/_actions_mobile.html.erb" => "stubbed content"
    stub_template "dashboards/_analytics.html.erb" => "stubbed content"
    stub_template "dashboards/_actions.html.erb" => "stubbed content"

    Imgproxy.config.key = "secret"
    Imgproxy.config.salt = "secret"
    SiteConfig.mascot_image_url = "https://i.imgur.com/fKYKgo4.png"
  end

  after do
    Imgproxy.config.key = nil
    Imgproxy.config.endpoint = nil
    SiteConfig.mascot_image_url = nil
  end

  context "when using Imgproxy" do
    it "renders mascot image properly" do
      assign(:user, create(:user))
      assign(:articles, [])
      render
      expect(rendered).to match(%r{/w:300/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end
  end
end
