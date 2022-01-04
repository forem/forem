require "rails_helper"

RSpec.describe UnifiedEmbed::Tag, type: :liquid_tag do
  it "delegates parsing to the link-matching class" do
    link = "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"

    allow(GistTag).to receive(:new).and_call_original
    parsed_tag = Liquid::Template.parse("{% embed #{link} %}")
    expect { parsed_tag.render }.not_to raise_error
    expect(GistTag).to have_received(:new)
  end

  it "renders an A-tag when no link-matching class is found" do
    link = "https://takeonrules.com/about"
    parsed_tag = Liquid::Template.parse("{% embed #{link} %}")
    expect(parsed_tag.render).to eq(%(<a href="#{link}">#{link}</a>))
  end
end
