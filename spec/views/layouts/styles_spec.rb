require "rails_helper"

RSpec.describe "layouts/_styles" do
  it "renders all stylesheet link tags with data-instant-track attribute" do
    render partial: "layouts/styles", locals: { qualifier: "main" }

    doc = Nokogiri::HTML.fragment(rendered)
    %w[minimal views crayons].each do |name|
      link = doc.at_css("link#main-#{name}-stylesheet")
      expect(link["data-instant-track"]).to eq("true")
    end
  end
end
