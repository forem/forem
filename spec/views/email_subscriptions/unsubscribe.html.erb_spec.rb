require "rails_helper"

RSpec.describe "email_subscriptions/unsubscribe.html.erb", type: :view do
  it "works" do
    assign(:email_type, "#{Settings::General.community_name} digest emails")
    render
    expect(rendered).to include("You have been unsubscribed from #{Settings::General.community_name} digest emails. 😔")
  end
end
