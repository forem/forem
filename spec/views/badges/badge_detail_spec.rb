require "rails_helper"

RSpec.describe "badges/_badge_detail" do
  let(:badges) { create_list(:badge, 3) }

  def render_badge_details
    badges.map { |badge| render(partial: "badges/badge_detail", locals: { badge: badge }) }
  end

  it "renders the same close icon for every badge" do
    first, *rest = render_badge_details.map { |html| Nokogiri::HTML.fragment(html) }

    close_icon = first.at_css(".close svg.close_icon")
    expect(close_icon).to be_present
    expect(close_icon["aria-hidden"]).to eq("true")
    expect(close_icon.at_css("title").text).to eq(I18n.t("views.badges.icon_close"))
    rest.each { |html| expect(html.at_css(".close svg.close_icon").to_html).to eq(close_icon.to_html) }
  end

  it "builds the close icon SVG only once per view" do
    allow(view).to receive(:inline_svg_tag).and_call_original

    render_badge_details

    expect(view).to have_received(:inline_svg_tag).with("x.svg", hash_including(class: "close_icon")).once
  end
end
