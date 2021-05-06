require "rails_helper"

RSpec.describe LogoComponent, type: :component do
  let(:community_name) { Settings::Community.community_name }
  let(:svg) { file_fixture("300x100.svg").read }

  it "renders component", :aggregate_failures do
    render_inline(described_class.new(community_name: community_name))

    expect(rendered_component).to have_css("a[href='#{root_path}']")
    expect(rendered_component).to have_css("a[aria-label='#{community_name} Home']")
    expect(rendered_component).to have_css("span", text: community_name)
  end

  it "renders component when given a logo svg", :aggregate_failures do
    render_inline(described_class.new(community_name: community_name, svg: svg))

    expect(rendered_component).to have_css("a[href='#{root_path}']")
    expect(rendered_component).to have_css("a[aria-label='#{community_name} Home']")
    expect(rendered_component).not_to have_css("span", text: community_name)

    expect(rendered_component).to have_text("<svg")
  end
end
