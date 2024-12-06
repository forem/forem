require 'spec_helper'
require 'resolv'

class PrivateIPAddressError < StandardError; end

describe MetaInspector do
  describe "redirections" do
    context "when redirections are turned off" do
      it "disallows redirections" do
        page = MetaInspector.new("http://facebook.com", :allow_redirections => false)

        expect(page.url).to eq("http://facebook.com/")
      end
    end

    context "when redirections are on (default)" do
      it "allows follows redirections" do
        page = MetaInspector.new("http://facebook.com")

        expect(page.url).to eq("https://www.facebook.com/")
      end
    end

    context "when there are too many redirects" do
      before do
        12.times { |i| register_redirect(i, i+1) }
      end

      it "raises an error" do
        expect {
          MetaInspector.new("http://example.org/1")
        }.to raise_error MetaInspector::RequestError
      end
    end

    context "when there are cookies required for proper redirection" do
      it "allows follows redirections while sending the cookies" do
        stub_request(:get, "http://blogs.clarionledger.com/dechols/2014/03/24/digital-medicine/")
          .to_return(:status => 302,
                     :headers => {
                                   "Location" => "http://blogs.clarionledger.com/dechols/2014/03/24/digital-medicine/?nclick_check=1",
                                   "Set-Cookie" => "EMETA_COOKIE_CHECK=1; path=/; domain=clarionledger.com"
                                 })

        stub_request(:get, "http://blogs.clarionledger.com/dechols/2014/03/24/digital-medicine/?nclick_check=1")
          .with(:headers => {"Cookie" => "EMETA_COOKIE_CHECK=1"})

        page = MetaInspector.new("http://blogs.clarionledger.com/dechols/2014/03/24/digital-medicine/")

        expect(page.url).to eq("http://blogs.clarionledger.com/dechols/2014/03/24/digital-medicine/?nclick_check=1")
      end
    end

    context "when there is a callback to be ran between redirects that blocks redirections to private IP addresses" do
      it "raises an exception" do
        stub_request(:get, "https://www.facebook.com/")
          .to_return(:status => 302,
                     :headers => { "Location" => "http://10.0.0.0/" })

        redirect_options = {
          callback: proc do |_previous_response, next_request|
            ip_address = Resolv.getaddress(next_request.url.host)
            raise PrivateIPAddressError if IPAddr.new(ip_address).private?
          end
        }

        expect {
          MetaInspector.new("https://www.facebook.com/", faraday_options: { redirect: redirect_options })
        }.to raise_error PrivateIPAddressError
      end
    end
  end

  private

  def register_redirect(from, to)
    stub_request(:get, "http://example.org/#{from}")
      .to_return(:status => 302, :body => "", :headers => { "Location" => "http://example.org/#{to}" })
  end
end
