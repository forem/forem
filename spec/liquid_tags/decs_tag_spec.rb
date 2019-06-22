require "rails_helper"

RSpec.describe DecsTag, type: :liquid_template do
  setup { Liquid::Template.register_tag("decs", DecsTag) }

  subject { Liquid::Template.parse("{% decs #{link} %}") }

  let(:stubbed_scraper) { instance_double("DECSSnippetService") }
  let(:decs_link) { "https://www.decs.xyz/creativex.id/0377f202-661b-ca5f-2d88-cb2c2cbc9057/main" }
  let(:response) do
    {
      title: "DECS Tour - Snippet example",
      description: "Guided tour will walk you through all the functionality of DECS web app and this is an example description of the snippet. Use this field to briefly describe what you are storing in this snippet and what does it do. Simple!",
      url: "https://www.decs.xyz/creativex.id/0377f202-661b-ca5f-2d88-cb2c2cbc9057/main",
      type: "rich",
      html: "<iframe width='600' height='329' src='https://www.decs.xyz/creativex.id/0377f202-661b-ca5f-2d88-cb2c2cbc9057/main' frameborder='0'></iframe>",
      width: 600,
      height: 329,
      version: "1.0",
      provider_name: "DECS",
      provider_url: "https://www.decs.xyz",
      author_name: "Venkata Chandrasekhar Nainala",
      author_url: "https://gaia.blockstack.org/hub/1F5xX8hpB3SKqeNV2aHNoSatBA1eW2CoHZ//avatar-0"
    }
  end

  def generate_decs_tag(link)
    Liquid::Template.parse("{% decs #{link} %}")
  end

  context "when given valid decs url" do
    before do
      allow(DECSSnippetService).to receive(:new).with("https://www.decs.xyz/oembed?url=" + decs_link).and_return(stubbed_scraper)
      allow(stubbed_scraper).to receive(:call).and_return(response)
    end

    it "renders decs html" do
      liquid = generate_decs_tag(decs_link)
      expect(liquid.render).to include("<iframe")
    end
  end

  it "raises an error when invalid" do
    expect { generate_decs_tag("invalid link") }.to raise_error("Invalid DECS Code Snippet URL")
  end
end
