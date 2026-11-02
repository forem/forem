require "rails_helper"

RSpec.describe Feeds::ValidateUrl, :vcr, type: :service do
  let(:invalid_feed_url) { "https://example.com" }
  let(:valid_feed_url) { "https://medium.com/feed/@vaidehijoshi" }
  let(:test_url) { "https://example.com/feed.xml" }

  it "returns false for empty URL" do
    expect(described_class.call("")).to be(false)
  end

  it "returns false for nil URL" do
    expect(described_class.call(nil)).to be(false)
  end

  it "strips whitespace from URL", vcr: { cassette_name: "feeds_import_medium_vaidehi" } do
    expect(described_class.call("  #{valid_feed_url}  ")).to be(true)
  end

  it "returns false for an invalid feed URL", vcr: { cassette_name: "feeds_validate_url_invalid" } do
    expect(described_class.call(invalid_feed_url)).to be(false)
  end

  it "returns true for a valid feed URL", vcr: { cassette_name: "feeds_import_medium_vaidehi" } do
    expect(described_class.call(valid_feed_url)).to be(true)
  end

  describe "HTTP error status handling across locales" do
    %i[en fr pt].each do |locale|
      context "with #{locale} locale" do
        it "raises localized bot protection error for 401" do
          stub_request(:get, test_url).to_return(status: 401, body: "Unauthorized")

          I18n.with_locale(locale) do
            expect { described_class.call(test_url) }
              .to raise_error(StandardError, I18n.t("feeds.validate_url.bot_protection"))
          end
        end

        it "raises localized bot protection error for 403" do
          stub_request(:get, test_url).to_return(status: 403, body: "Forbidden")

          I18n.with_locale(locale) do
            expect { described_class.call(test_url) }
              .to raise_error(StandardError, I18n.t("feeds.validate_url.bot_protection"))
          end
        end

        it "raises localized not found error for 404" do
          stub_request(:get, test_url).to_return(status: 404, body: "Not Found")

          I18n.with_locale(locale) do
            expect { described_class.call(test_url) }
              .to raise_error(StandardError, I18n.t("feeds.validate_url.not_found"))
          end
        end

        it "raises localized bot protection error for 429" do
          stub_request(:get, test_url).to_return(status: 429, body: "Too Many Requests")

          I18n.with_locale(locale) do
            expect { described_class.call(test_url) }
              .to raise_error(StandardError, I18n.t("feeds.validate_url.bot_protection"))
          end
        end

        it "raises localized server error for 500" do
          stub_request(:get, test_url).to_return(status: 500, body: "Server Error")

          I18n.with_locale(locale) do
            expect { described_class.call(test_url) }
              .to raise_error(StandardError, I18n.t("feeds.validate_url.server_error"))
          end
        end

        it "raises localized generic status error for unexpected non-2xx" do
          stub_request(:get, test_url).to_return(status: 502, body: "Bad Gateway")

          I18n.with_locale(locale) do
            expect { described_class.call(test_url) }
              .to raise_error(StandardError, I18n.t("feeds.validate_url.status_error", code: 502))
          end
        end

        it "raises localized network error for network exceptions" do
          stub_request(:get, test_url).to_raise(SocketError.new("Failed to open TCP connection to example.com:443"))

          I18n.with_locale(locale) do
            expect { described_class.call(test_url) }
              .to raise_error(StandardError, I18n.t("feeds.validate_url.network_error"))
          end
        end
      end
    end
  end

  describe "network exception handling" do
    it "rescues Net::OpenTimeout and raises localized network error without leaking backtrace" do
      stub_request(:get, test_url).to_raise(Net::OpenTimeout.new("execution expired"))

      expect { described_class.call(test_url) }
        .to raise_error(StandardError, I18n.t("feeds.validate_url.network_error"))
    end

    it "rescues OpenSSL::SSL::SSLError and raises localized network error without leaking backtrace" do
      stub_request(:get, test_url).to_raise(OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 peerkey=..."))

      expect { described_class.call(test_url) }
        .to raise_error(StandardError, I18n.t("feeds.validate_url.network_error"))
    end

    it "logs a warning when network exceptions are rescued" do
      allow(Rails.logger).to receive(:warn)
      stub_request(:get, test_url).to_raise(SocketError.new("getaddrinfo: Name or service not known"))

      expect { described_class.call(test_url) }.to raise_error(StandardError)
      expect(Rails.logger).to have_received(:warn).with(a_string_including("Feeds::ValidateUrl network error"))
    end
  end
end
