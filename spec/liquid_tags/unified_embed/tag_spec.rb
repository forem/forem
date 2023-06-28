require "rails_helper"

RSpec.describe UnifiedEmbed::Tag, type: :liquid_tag do
  let(:listing) { create(:listing) }

  # See https://github.com/forem/forem/issues/17679; Note the document has `og:title` but not
  # `og:url`; should we fallback to the given URL instead?
  # rubocop:disable RSpec/ExampleLength
  it "handles https://guides.rubyonrails.org" do
    link = "https://guides.rubyonrails.org/routing.html"
    stub_request(:head, link)
      .with(
        headers: {
          "Accept" => "*/*",
          "User-Agent" => "DEV(local) (#{URL.url})"
        },
      )
      .to_return(status: 200, body: "", headers: {})

    stub_request(:get, link)
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "User-Agent" => "DEV(local) (http://localhost:3000)"
        },
      )
      .to_return(
        status: 200,
        body: Rails.root.join("spec/fixtures/files/guides.rubyonrails.org-routing.html").read,
        headers: {},
      )

    parsed_tag = Liquid::Template.parse("{% embed #{link} %}")
    expect(parsed_tag.render).to include("<a href=\"#{link}\"")
  end
  # rubocop:enable RSpec/ExampleLength

  it "delegates parsing to the link-matching class" do
    link = "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"

    allow(GistTag).to receive(:new).and_call_original
    stub_network_request(url: link)
    parsed_tag = Liquid::Template.parse("{% embed #{link} %}")

    expect { parsed_tag.render }.not_to raise_error
    expect(GistTag).to have_received(:new)
  end

  it "delegates parsing to the link-matching class when there are options", vcr: true do
    link = "https://github.com/rust-lang/rust"

    allow(GithubTag).to receive(:new).and_call_original

    VCR.use_cassette("github_client_repository_no_readme") do
      stub_network_request(url: link)
      parsed_tag = Liquid::Template.parse("{% embed #{link} noreadme %}")

      expect { parsed_tag.render }.not_to raise_error
      expect(GithubTag).to have_received(:new)
    end
  end

  it "raises an error when link cannot be found" do
    link = "https://takeonrules.com/goes-nowhere"

    expect do
      stub_network_request(url: link, status_code: 404)
      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "URL provided was not found; please check and try again")
  end

  it "repeats validation when link returns not-allowed", vcr: true do
    link = "https://takeonrules.com/not-allowed-response"

    allow(described_class).to receive(:validate_link).and_call_original

    stub_network_request(url: link, status_code: 405)
    stub_metainspector_request(link)
    stub_network_request(url: link, method: :get)

    Liquid::Template.parse("{% embed #{link} %}")

    expect(described_class).to have_received(:validate_link).twice
  end

  it "raises an error when link returns not-allowed too many times" do
    link = "https://takeonrules.com/not-allowed-response"
    stub_const("UnifiedEmbed::Tag::MAX_REDIRECTION_COUNT", 0)

    expect do
      stub_network_request(url: link, status_code: 405)
      stub_metainspector_request(link)
      stub_network_request(url: link, method: :get)

      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "URL provided may have a typo or error; please check and try again")
  end

  it "repeats validation when link returns redirect", vcr: true do
    link = "https://bit.ly/hoagintake"

    allow(described_class).to receive(:validate_link).and_call_original

    VCR.use_cassette("redirected_url_fetch") do
      Liquid::Template.parse("{% embed #{link} %}")

      expect(described_class).to have_received(:validate_link).twice
    end
  end

  it "raises error when link redirects too many times in a row", vcr: true do
    link = "https://bit.ly/hoagintake"
    stub_const("UnifiedEmbed::Tag::MAX_REDIRECTION_COUNT", 0)

    VCR.use_cassette("redirected_url_fetch") do
      expect do
        Liquid::Template.parse("{% embed #{link} %}")
      end.to raise_error(StandardError, "Embedded link redirected too many times.")
    end
  end

  it "calls OpenGraphTag when no link-matching class is found", vcr: true do
    link = "https://takeonrules.com/about/"

    allow(OpenGraphTag).to receive(:new).and_call_original

    VCR.use_cassette("takeonrules_fetch") do
      expect do
        stub_network_request(url: link)
        Liquid::Template.parse("{% embed #{link} %}")
      end.not_to raise_error
    end

    expect(OpenGraphTag).to have_received(:new)
  end

  it "raises an error when Listings are disabled and a listing URL is embedded" do
    allow(Listing).to receive(:feature_enabled?).and_return(false)
    listing_url = "#{URL.url}/listings/#{listing.slug}"

    expect do
      Liquid::Template.parse("{% embed #{listing_url} %}")
    end.to raise_error(StandardError, "Listings are disabled on this Forem; cannot embed a listing URL")
  end

  it "sanitizes community_name into safe user-agent string" do
    unsafe = "Some of this.is_not_safe (but that's okay?) 🌱"
    result = described_class.safe_user_agent(unsafe)
    expect(result).to eq("Some of this.is_not_safe (but that-s okay-) -")
  end
end
