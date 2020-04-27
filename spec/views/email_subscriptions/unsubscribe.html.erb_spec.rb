require "rails_helper"

RSpec.describe "email_subscriptions/unsubscribe.html.erb", type: :view do
  it "works" do
    assign(:email_type, "#{ApplicationConfig['COMMUNITY_NAME']} digest emails")
    render
    Approvals.verify(rendered, name: "email_subscriptions/unsubscribe", format: :html)
  end
end
