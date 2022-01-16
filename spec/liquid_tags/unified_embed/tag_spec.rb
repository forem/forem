require "rails_helper"

RSpec.describe UnifiedEmbed::Tag, type: :liquid_tag do
  it "delegates parsing to the link-matching class" do
    link = "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"

    allow(GistTag).to receive(:new).and_call_original
    parsed_tag = Liquid::Template.parse("{% embed #{link} %}")
    expect { parsed_tag.render }.not_to raise_error
    expect(GistTag).to have_received(:new)
  end

  it "raises an error when no link-matching class is found" do
    link = "https://takeonrules.com/about"

    expect do
      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "Embed URL not valid")
  end
end
