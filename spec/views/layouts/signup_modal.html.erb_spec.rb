require "rails_helper"

RSpec.describe "layouts/_signup_modal.html.erb", type: :view do
  xit "has the tagline" do
    render
    expect(rendered).to have_text(SiteConfig.tagline)
  end
end
