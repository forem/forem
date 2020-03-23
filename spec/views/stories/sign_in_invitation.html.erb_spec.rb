require "rails_helper"

RSpec.describe "stories/_sign_in_invitation.html.erb", type: :view do
  it "has the community member description" do
    render
    expect(rendered).to have_text(SiteConfig.community_member_description)
  end
end
