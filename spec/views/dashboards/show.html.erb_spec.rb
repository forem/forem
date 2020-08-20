require "rails_helper"

RSpec.describe "dashboards/show.html.erb", type: :view do
  it "works" do
    stub_template "actions_mobile" => "This content"
    stub_template "analytics" => "This content"
    assign(:user, create(:user))
    render
  end
end
