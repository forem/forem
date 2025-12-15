require "rails_helper"

RSpec.describe UnifiedEmbed::Tag, type: :liquid_tag do
  let(:listing) { create(:listing) }

  # See https://github.com/forem/forem/issues/17679; Note the document has `og:title` but not
  # `og:url`; should we fallback to the given URL instead?
  it "handles https://guides.rubyonrails.org" do
    link = "https://guides.rubyonrails.org/routing.html"
    safe_agent = Settings::Community.community_name.gsub(/[^-_.()a-zA-Z0-9 ]+/, "-")
    stub_request(:head, link)
      .with(
        headers: {
          "Accept" => "*/*",
          "User-Agent" => "ForemLinkValidator/1.0 (+#{URL.url}; #{safe_agent})"
        },
      )
      .to_return(status: 200, body: "", headers: {})

    stub_request(:get, link)
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "User-Agent" => "DEV(local) (http://forem.test)"
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

  it "delegates parsing to the link-matching class when there are options" do
    link = "https://github.com/rust-lang/rust"

    allow(GithubTag).to receive(:new).and_call_original

    # Mock the GitHub client to avoid complex API interactions
    mock_owner = double("owner", login: "rust-lang")
    mock_repository = double("repository", 
      html_url: "https://github.com/rust-lang/rust",
      name: "rust",
      description: "Empowering everyone to build reliable and efficient software.",
      owner: mock_owner
    )
    mock_github_client = double("github_client")
    allow(mock_github_client).to receive(:repository).and_return(mock_repository)
    allow(mock_github_client).to receive(:readme).and_return("<p>Mock README content</p>")
    allow(Github::OauthClient).to receive(:new).and_return(mock_github_client)

    stub_network_request(url: link)
    
    parsed_tag = Liquid::Template.parse("{% embed #{link} noreadme %}")

    expect { parsed_tag.render }.not_to raise_error
    expect(GithubTag).to have_received(:new)
  end

  it "raises an error when link cannot be found" do
    link = "https://takeonrules.com/goes-nowhere"

    expect do
      stub_network_request(url: link, status_code: 404)
      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "URL provided was not found; please check and try again")
  end

  it "repeats validation when link returns not-allowed", :vcr do
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

  it "repeats validation when link returns redirect", :vcr do
    link = "https://bit.ly/hoagintake"

    allow(described_class).to receive(:validate_link).and_call_original

    VCR.use_cassette("redirected_url_fetch") do
      Liquid::Template.parse("{% embed #{link} %}")

      expect(described_class).to have_received(:validate_link).twice
    end
  end

  it "raises error when link redirects too many times in a row", :vcr do
    link = "https://bit.ly/hoagintake"
    stub_const("UnifiedEmbed::Tag::MAX_REDIRECTION_COUNT", 0)

    VCR.use_cassette("redirected_url_fetch") do
      expect do
        Liquid::Template.parse("{% embed #{link} %}")
      end.to raise_error(StandardError, "Embedded link redirected too many times.")
    end
  end

  it "calls OpenGraphTag when no link-matching class is found", :vcr do
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

  it "falls back to a simple link card when validation raises a network/SSL error" do
    link = "https://example.com/some/path"

    allow(described_class).to receive(:validate_link).with(input: link).and_raise(OpenSSL::SSL::SSLError.new("certificate verify failed"))

    liquid = Liquid::Template.parse("{% embed #{link} %}")

    expect { liquid.render }.to_not raise_error
    rendered = liquid.render

    # Uses the OpenGraph fallback card with no metadata
    expect(rendered).to include("crayons-card")
    expect(rendered).to include("c-embed")
    # Displays a cleaned-up, human-friendly version of the URL
    expect(rendered).to include("example.com / some/path")
    # Includes a visual link-out icon (inline SVG with external-link.svg)
    expect(rendered).to include("external-link.svg")
  end

  it "sanitizes community_name into safe user-agent string" do
    unsafe = "Some of this.is_not_safe (but that's okay?) 🌱"
    result = described_class.safe_user_agent(unsafe)
    expect(result).to eq("Some of this.is_not_safe (but that-s okay-) -")
  end

  describe "minimal keyword" do
    let(:user) { create(:user, username: "testuser") }
    let(:article) { create(:article, user: user, title: "Test Article") }
    let(:youtube_url) { "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }
    let(:forem_url) { "#{URL.url}/#{user.username}/#{article.slug}" }

    it "uses OpenGraphTag for non-allowlisted URLs when minimal is specified" do
      stub_network_request(url: youtube_url)
      stub_metainspector_request(youtube_url)
      stub_request(:get, youtube_url)
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "DEV(local) (http://forem.test)"
          },
        )
        .to_return(status: 200, body: "", headers: {})
      liquid = Liquid::Template.parse("{% embed #{youtube_url} minimal %}")
      expect(liquid.render).to include("c-embed") # OpenGraphTag uses the c-embed class
    end

    it "uses LinkTag for allowlisted URLs when minimal is specified" do
      stub_network_request(url: forem_url)
      liquid = Liquid::Template.parse("{% embed #{forem_url} minimal %}")
      expect(liquid.render).to include("ltag__link") # LinkTag uses the ltag__link class
    end

    it "uses normal embed behavior when minimal is not specified" do
      stub_network_request(url: youtube_url)
      liquid = Liquid::Template.parse("{% embed #{youtube_url} %}")
      # Should use YoutubeTag which renders differently than OpenGraphTag
      expect(liquid.render).not_to include("c-embed")
    end

    it "handles minimal keyword in any position" do
      stub_network_request(url: youtube_url)
      stub_metainspector_request(youtube_url)
      stub_request(:get, youtube_url)
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "DEV(local) (http://forem.test)"
          },
        )
        .to_return(status: 200, body: "", headers: {})
      liquid = Liquid::Template.parse("{% embed minimal #{youtube_url} %}")
      expect(liquid.render).to include("c-embed")
    end

    it "handles multiple spaces and minimal keyword" do
      stub_network_request(url: youtube_url)
      stub_metainspector_request(youtube_url)
      stub_request(:get, youtube_url)
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "DEV(local) (http://forem.test)"
          },
        )
        .to_return(status: 200, body: "", headers: {})
      liquid = Liquid::Template.parse("{% embed   #{youtube_url}   minimal   %}")
      expect(liquid.render).to include("c-embed")
    end
  end

  describe "SSRF protection" do
    describe "#private_ip?" do
      it "blocks localhost variations" do
        expect(described_class.private_ip?("localhost")).to be_truthy
        expect(described_class.private_ip?("127.0.0.1")).to be_truthy
        expect(described_class.private_ip?("::1")).to be_truthy
      end

      it "blocks private IPv4 ranges" do
        expect(described_class.private_ip?("192.168.1.1")).to be_truthy
        expect(described_class.private_ip?("10.0.0.1")).to be_truthy
        expect(described_class.private_ip?("172.16.0.1")).to be_truthy
      end

      it "blocks loopback addresses" do
        expect(described_class.private_ip?("127.0.0.2")).to be_truthy
      end

      it "allows public IP addresses" do
        expect(described_class.private_ip?("8.8.8.8")).to be_falsy
        expect(described_class.private_ip?("1.1.1.1")).to be_falsy
        expect(described_class.private_ip?("208.67.222.222")).to be_falsy
      end

      it "allows public domain names" do
        # Stub DNS resolution to return public IP
        allow(Addrinfo).to receive(:getaddrinfo).with("github.com", nil, nil, :STREAM)
          .and_return([double(ip_address: "140.82.112.3")])
        
        expect(described_class.private_ip?("github.com")).to be_falsy
      end

      it "blocks domain names that resolve to private IPs" do
        # Stub DNS resolution to return private IP
        allow(Addrinfo).to receive(:getaddrinfo).with("internal.company.com", nil, nil, :STREAM)
          .and_return([double(ip_address: "192.168.1.100")])
        
        expect(described_class.private_ip?("internal.company.com")).to be_truthy
      end

      it "allows domains that fail to resolve" do
        allow(Addrinfo).to receive(:getaddrinfo).and_raise(SocketError.new("Name resolution failure"))
        
        expect(described_class.private_ip?("nonexistent.domain")).to be_falsy
      end
    end

    describe "validate_link with SSRF protection" do
      it "raises error for private IP addresses" do
        expect do
          described_class.validate_link(input: "http://192.168.1.1/test")
        end.to raise_error(StandardError, "URL provided may have a typo or error; please check and try again")
      end

      it "raises error for localhost" do
        expect do
          described_class.validate_link(input: "http://localhost:3000/test")
        end.to raise_error(StandardError, "URL provided may have a typo or error; please check and try again")
      end

      it "allows public domains" do
        link = "https://github.com/forem/forem"
        
        # Stub DNS resolution to return public IP
        allow(Addrinfo).to receive(:getaddrinfo).with("github.com", nil, nil, :STREAM)
          .and_return([double(ip_address: "140.82.112.3")])
        
        stub_network_request(url: link)
        
        expect do
          described_class.validate_link(input: link)
        end.not_to raise_error
      end

      it "bypasses SSRF protection for Twitter/X URLs" do
        twitter_link = "https://twitter.com/user/status/123"
        
        expect do
          described_class.validate_link(input: twitter_link)
        end.not_to raise_error
      end

      it "bypasses SSRF protection for Bluesky URLs" do
        bsky_link = "https://bsky.app/profile/user.bsky.social/post/abc123"
        
        expect do
          described_class.validate_link(input: bsky_link)
        end.not_to raise_error
      end
    end

    describe "HTTP timeout settings" do
      it "sets proper timeout values during validation" do
        link = "https://example.com/test"
        
        # Stub DNS resolution
        allow(Addrinfo).to receive(:getaddrinfo).with("example.com", nil, nil, :STREAM)
          .and_return([double(ip_address: "93.184.216.34")])
        
        # Mock the HTTP object to verify timeouts are set
        http_mock = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_mock)
        allow(http_mock).to receive(:use_ssl=)
        allow(http_mock).to receive(:open_timeout=).with(10)
        allow(http_mock).to receive(:read_timeout=).with(15)
        allow(http_mock).to receive(:request).and_return(Net::HTTPSuccess.new("1.1", "200", "OK"))
        
        described_class.validate_link(input: link)
        
        expect(http_mock).to have_received(:open_timeout=).with(10)
        expect(http_mock).to have_received(:read_timeout=).with(15)
      end
    end

    describe "CloudFlare-compatible User-Agent" do
      it "uses ForemLinkValidator User-Agent format" do
        link = "https://example.com/test"
        
        # Stub DNS resolution
        allow(Addrinfo).to receive(:getaddrinfo).with("example.com", nil, nil, :STREAM)
          .and_return([double(ip_address: "93.184.216.34")])
        
        # Mock HTTP request to capture User-Agent
        http_mock = instance_double(Net::HTTP)
        request_mock = instance_double(Net::HTTP::Head)
        allow(Net::HTTP).to receive(:new).and_return(http_mock)
        allow(Net::HTTP::Head).to receive(:new).and_return(request_mock)
        allow(http_mock).to receive(:use_ssl=)
        allow(http_mock).to receive(:open_timeout=)
        allow(http_mock).to receive(:read_timeout=)
        allow(http_mock).to receive(:request).and_return(Net::HTTPSuccess.new("1.1", "200", "OK"))
        
        # Capture User-Agent assignment
        expect(request_mock).to receive(:[]=).with("User-Agent", match(/^ForemLinkValidator\/1\.0 \(/))
        
        described_class.validate_link(input: link)
      end
    end

    describe "redirect and auth handling" do
      it "resolves relative redirects into absolute URLs" do
        link = "https://iwantmyname.com"

        # Ensure SSRF resolution allows the host
        allow(Addrinfo).to receive(:getaddrinfo).with("iwantmyname.com", nil, nil, :STREAM)
          .and_return([double(ip_address: "93.184.216.34")])

        # First HEAD returns a relative Location
        stub_request(:head, link)
          .to_return(status: 302, headers: { "Location" => "/en/" })

        # Second HEAD hits the resolved absolute URL
        stub_request(:head, "https://iwantmyname.com/en/")
          .to_return(status: 200)

        expect(described_class.validate_link(input: link)).to eq("https://iwantmyname.com/en/")
      end

      it "treats 403 Forbidden as valid for validation purposes" do
        link = "https://tonethreads.com/artists/new"

        allow(Addrinfo).to receive(:getaddrinfo).with("tonethreads.com", nil, nil, :STREAM)
          .and_return([double(ip_address: "93.184.216.34")])

        stub_request(:head, link).to_return(status: 403)

        expect(described_class.validate_link(input: link)).to eq(link)
      end

      it "handles AddressFamilyError gracefully in private_ip?" do
        link_host = "weird.host"

        # Simulate AddressFamilyError on the first IPAddr.new(hostname) attempt
        allow(IPAddr).to receive(:new).with(link_host).and_raise(IPAddr::AddressFamilyError)
        # Then resolving the hostname yields a public IP
        allow(Addrinfo).to receive(:getaddrinfo).with(link_host, nil, nil, :STREAM)
          .and_return([double(ip_address: "93.184.216.34")])
        # Allow the actual IP address check to proceed normally
        allow(IPAddr).to receive(:new).with("93.184.216.34").and_call_original

        expect(described_class.private_ip?(link_host)).to be_falsey
      end
    end
  end
end
