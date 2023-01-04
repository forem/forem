require "rails_helper"

RSpec.describe "stories/_sign_in_invitation" do
  it "has the community member label" do
    render
    expect(rendered).to have_text(Settings::Community.member_label.pluralize)
  end
end
