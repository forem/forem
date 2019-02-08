require "rails_helper"

RSpec.describe "email_subscriptions/unsubscribe.html.erb", type: :view do
  it "works" do
    assign(:email_type, "DEV digest emails")
    render
    verify(format: :html) { rendered }
  end
end
