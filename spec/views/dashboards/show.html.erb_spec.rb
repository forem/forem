require "rails_helper"

RSpec.describe "dashboards/show" do
  before do
    stub_template "dashboards/_actions_mobile.html.erb" => "stubbed content"
    stub_template "dashboards/_analytics.html.erb" => "stubbed content"
    stub_template "dashboards/_actions.html.erb" => "stubbed content"

    allow(Images::Optimizer).to receive(:imgproxy_enabled?).and_return(true)
    allow(Settings::General).to receive(:mascot_image_url).and_return("https://i.imgur.com/fKYKgo4.png")

    # These three lines are required for assisting the view in handling a policy.
    # This issue highlights a continued problem: https://github.com/varvet/pundit/issues/163
    view.extend(Pundit::Authorization)
    policy = instance_double(ArticlePolicy, create?: true)
    allow(view).to receive(:policy).and_return(policy)
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
