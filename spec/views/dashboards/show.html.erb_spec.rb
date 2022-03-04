require "rails_helper"

RSpec.describe "dashboards/show.html.erb", type: :view do
  before do
    stub_template "dashboards/_actions_mobile.html.erb" => "stubbed content"
    stub_template "dashboards/_analytics.html.erb" => "stubbed content"
    stub_template "dashboards/_actions.html.erb" => "stubbed content"

    allow(Images::Optimizer).to receive(:imgproxy_enabled?).and_return(true)
    allow(Settings::General).to receive(:mascot_image_url).and_return("https://i.imgur.com/fKYKgo4.png")
  end

  context "when using Imgproxy" do
    it "renders mascot image properly" do
      assign(:user, create(:user))
      assign(:articles, [])
      render
      expect(rendered).to match(%r{/w:300/mb:500000/ar:1/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end
  end
end
