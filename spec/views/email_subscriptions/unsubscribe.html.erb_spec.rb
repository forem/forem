require "rails_helper"

RSpec.describe "email_subscriptions/unsubscribe" do
  it "has unsubscribed info" do
    assign(:email_type, "#{Settings::Community.community_name} digest emails")
    render
    expect(rendered)
      .to include("You have been unsubscribed from #{Settings::Community.community_name} digest emails. 😔")
  end
end
