require "rails_helper"

RSpec.describe DotnetFiddleTag, type: :liquid_tag do
  describe "#link" do
    let(:dotnetfiddle_link) { "https://dotnetfiddle.net/Widget/v2kx9jcd" }

    xss_links = %w(
      //evil.com/?dotnetfiddle.net
      https://dotnetfiddle.net.evil.com
      https://dotnetfiddle.net/some_username/pen/" onload='alert("xss")'
    )

    def generate_new_liquid(link)
      Liquid::Template.register_tag("dotnetfiddle", DotnetFiddleTag)
      Liquid::Template.parse("{% dotnetfiddle #{link} %}")
    end

    it "accepts dotnet link" do
      liquid = generate_new_liquid(dotnetfiddle_link)

      expect(liquid.render).to include("<iframe")
        .and include('src="https://dotnetfiddle.net/Widget/v2kx9jcd"')
    end

    it "accepts dotnet link with a / at the end" do
      dotnetfiddle_link = "https://dotnetfiddle.net/Widget/v2kx9jcd/"
      expect do
        generate_new_liquid(dotnetfiddle_link)
      end.not_to raise_error
    end

    it "rejects invalid dotnet link" do
      expect do
        generate_new_liquid("invalid_dotnet_link")
      end.to raise_error(StandardError)
    end

    it "rejects XSS attempts" do
      xss_links.each do |link|
        expect { generate_new_liquid(link) }.to raise_error(StandardError)
      end
    end
  end
end
