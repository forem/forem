require "rails_helper"

RSpec.describe RedditTag, type: :liquid_tag do
  before do
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    %w[reddit.com www.reddit.com].each do |host|
      allow(Addrinfo).to receive(:getaddrinfo)
        .with(host, nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])
    end
  end

  context "when it is an image post" do
    describe "#render" do
      let(:image_post) do
        "https://www.reddit.com/r/aww/comments/ag3s4b/ive_waited_28_years_to_finally_havr_my_first_pet"
      end
      let(:response) do
        {
          "author" => "Miaogua007",
          "title" => "I've waited 28 years to …Everyone, meet Mycroft.",
          "post_url" => "https://www.reddit.com/r/aww/comments/ag3s4b/ive_waited_28_years_to_finally_havr_my_first_pet",
          "created_utc" => 1_547_520_425,
          "post_hint" => "image",
          "image_url" => "https://i.redd.it/jpqodmc83ia21.jpg",
          "thumbnail" => "https://b.thumbs.redditm…ge_mn1MHd6uirdou8H3o.jpg",
          "selftext" => "",
          "selftext_html" => nil
        }
      end

      def generate_reddit_liquid(url)
        Liquid::Template.register_tag("reddit", RedditTag)
        Liquid::Template.parse("{% reddit #{url} %}")
      end

      before do
        allow(HTTParty).to receive(:get).and_return([
                                                      {
                                                        "data" => {
                                                          "children" => [
                                                            { "data" => response },
                                                          ]
                                                        }
                                                      },
                                                    ])
      end

      it "renders reddit content" do
        reddit_liquid = generate_reddit_liquid(image_post)
        expect(reddit_liquid.render).to include("ltag__reddit")
        expect(reddit_liquid.render).to include(response["author"])
        expect(reddit_liquid.render).to include(response["thumbnail"])
      end
    end
  end

  context "when it is a text post" do
    describe "#render" do
      let(:text_post) do
        "https://www.reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession"
      end

      let(:response) do
        post_url = "https://www.reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession"

        {
          "author" => "scottkeyes",
          "title" => "I'm Scott from Scott's C…r the next 8 hours. AMA",
          "post_url" => post_url,
          "created_utc" => 1_547_470_871,
          "post_hint" => "self",
          "image_url" => "",
          "thumbnail" => "self",
          "selftext" => "I may have the world’s b…year for cheap flights!!",
          "selftext_html" => ""
        }
      end

      def generate_reddit_liquid(url)
        Liquid::Template.register_tag("reddit", RedditTag)
        Liquid::Template.parse("{% reddit #{url} %}")
      end

      before do
        allow(HTTParty).to receive(:get).and_return([
                                                      {
                                                        "data" => {
                                                          "children" => [
                                                            { "data" => response },
                                                          ]
                                                        }
                                                      },
                                                    ])
      end

      it "renders reddit content" do
        reddit_liquid = generate_reddit_liquid(text_post)
        expect(reddit_liquid.render).to include("ltag__reddit")
        expect(reddit_liquid.render).to include(response["author"])
      end

      it "supports apex reddit.com URLs" do
        apex_url = "https://reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession"
        reddit_liquid = generate_reddit_liquid(apex_url)
        expect(reddit_liquid.render).to include("ltag__reddit")
        expect(reddit_liquid.render).to include(response["author"])
      end

      it "supports explicit port 443 URLs" do
        port_url = "https://www.reddit.com:443/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession"
        reddit_liquid = generate_reddit_liquid(port_url)
        expect(reddit_liquid.render).to include("ltag__reddit")
        expect(reddit_liquid.render).to include(response["author"])
      end
    end
  end

  describe "URL and response validation" do
    def parse_reddit_liquid(url)
      Liquid::Template.register_tag("reddit", described_class)
      Liquid::Template.parse("{% reddit #{url} %}")
    end

    [
      "https://www.reddit.com",
      "https://reddit.com",
      "https://reddit.com.example.com/r/aww/comments/123",
      "https://reddit.com@127.0.0.1/r/aww/comments/123",
      "https://reddit.com:8080/r/aww/comments/123",
      "http://www.reddit.com/r/aww/comments/123",
      "https://www.reddit.com/r/aww unexpected_arg",
      "https://www.reddit.com?q=test",
      "not a url",
    ].each do |invalid_url|
      it "rejects #{invalid_url} without making an HTTP request" do
        allow(SafeHttp).to receive(:get)

        expect { parse_reddit_liquid(invalid_url) }
          .to raise_error(StandardError, I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: invalid_url))
        expect(SafeHttp).not_to have_received(:get)
      end
    end

    it "follows permitted redirects between allowed Reddit hosts" do
      apex_url = "https://reddit.com/r/aww/comments/ag3s4b/example"
      canonical_json_url = "https://www.reddit.com/r/aww/comments/ag3s4b/example.json"
      post_data = {
        "author" => "scottkeyes",
        "title" => "Example post",
        "created_utc" => 1_547_470_871,
        "post_hint" => "self",
        "selftext" => "Hello world"
      }

      stub_request(:get, "#{apex_url}.json")
        .to_return(status: 301, headers: { "Location" => canonical_json_url })
      stub_request(:get, canonical_json_url).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: [{ "data" => { "children" => [{ "data" => post_data }] } }].to_json,
      )

      expect(parse_reddit_liquid(apex_url).render).to include("Example post")
    end

    it "rejects redirects to unroutable addresses without fetching the redirect target" do
      reddit_url = "https://www.reddit.com/r/aww/comments/ag3s4b/example"
      internal_target = "http://10.0.0.5/status.json"
      stub_request(:get, "#{reddit_url}.json").to_return(status: 302, headers: { "Location" => internal_target })
      stub_request(:get, internal_target)

      expect { parse_reddit_liquid(reddit_url) }
        .to raise_error(StandardError, I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: reddit_url))
      expect(a_request(:get, internal_target)).not_to have_been_made
    end

    it "rejects redirects to off-domain hosts without fetching the redirect target" do
      reddit_url = "https://www.reddit.com/r/aww/comments/ag3s4b/example"
      external_target = "https://other.example/post.json"
      allow(Addrinfo).to receive(:getaddrinfo)
        .with("other.example", nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.20")])

      stub_request(:get, "#{reddit_url}.json").to_return(status: 302, headers: { "Location" => external_target })
      stub_request(:get, external_target)

      expect { parse_reddit_liquid(reddit_url) }
        .to raise_error(StandardError, I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: reddit_url))
      expect(a_request(:get, external_target)).not_to have_been_made
    end

    it "rejects redirects downgrading to HTTP without fetching the redirect target" do
      reddit_url = "https://www.reddit.com/r/aww/comments/ag3s4b/example"
      downgrade_target = "http://www.reddit.com/r/aww/comments/ag3s4b/example.json"
      stub_request(:get, "#{reddit_url}.json").to_return(status: 302, headers: { "Location" => downgrade_target })
      stub_request(:get, downgrade_target)

      expect { parse_reddit_liquid(reddit_url) }
        .to raise_error(StandardError, I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: reddit_url))
      expect(a_request(:get, downgrade_target)).not_to have_been_made
    end

    [
      { "message" => "Not Found", "error" => 404 },
      ["error"],
      [{ "data" => 1 }],
      [{ "data" => [] }],
      [{ "data" => { "children" => "oops" } }],
      [{ "data" => { "children" => [123] } }],
      [{ "data" => { "children" => [{ "data" => {} }] } }],
    ].each do |malformed_payload|
      it "raises an invalid link error when the JSON payload is #{malformed_payload.inspect}" do
        reddit_url = "https://www.reddit.com/r/aww/comments/missing"
        stub_request(:get, "#{reddit_url}.json").to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: malformed_payload.to_json,
        )

        expect { parse_reddit_liquid(reddit_url) }
          .to raise_error(StandardError, I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: reddit_url))
      end
    end

    it "raises an invalid link error when the JSON response is truncated" do
      reddit_url = "https://www.reddit.com/r/aww/comments/truncated"
      stub_request(:get, "#{reddit_url}.json").to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: "[{",
      )

      expect { parse_reddit_liquid(reddit_url) }
        .to raise_error(StandardError, I18n.t("liquid_tags.reddit_tag.invalid_reddit_link", url: reddit_url))
    end
  end
end
