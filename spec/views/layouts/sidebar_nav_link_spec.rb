require "rails_helper"

RSpec.describe "layouts/_sidebar_nav_link" do
  let(:custom_page_link) { build(:navigation_link, url: "/challenges", name: "Challenges") }
  let(:internal_link) { build(:navigation_link, url: "/tags", name: "Tags") }
  let(:page_prefix_link) { build(:navigation_link, url: "/page/about", name: "About") }

  it "renders data-no-instant for /challenges link" do
    render partial: "layouts/sidebar_nav_link", locals: { link: custom_page_link }
    expect(rendered).to include("data-no-instant")
  end

  it "renders data-no-instant for /page/* link" do
    render partial: "layouts/sidebar_nav_link", locals: { link: page_prefix_link }
    expect(rendered).to include("data-no-instant")
  end

  it "does not render data-no-instant for standard internal links" do
    render partial: "layouts/sidebar_nav_link", locals: { link: internal_link }
    expect(rendered).not_to include("data-no-instant")
  end
end
