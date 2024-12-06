require 'spec_helper'

describe MetaInspector::Request do
  it "raises an error if the URL is non-HTTP" do
    expect do
      MetaInspector::Request.new(url('ftp://ftp.example.com'))
    end.to raise_error(MetaInspector::RequestError)
  end

  describe "read" do
    it "should return the content of the page" do
      page_request = MetaInspector::Request.new(url('http://pagerankalert.com'))

      expect(page_request.read[0..14]).to eq("<!DOCTYPE html>")
    end

    it "can have a forced encoding" do
      page_request =
        MetaInspector::Request.new(url('http://example.com/invalid_utf8_byte_seq'))

      expect do
        page_request.read
      end.to raise_error(MetaInspector::RequestError, "invalid byte sequence in UTF-8")

      page_request_with_forced_encoding =
        MetaInspector::Request.new(url('http://example.com/invalid_utf8_byte_seq'), encoding: "UTF-8")

      expect do
        page_request_with_forced_encoding.read
      end.not_to raise_error
    end
  end

  describe "response" do
    it "contains the response status" do
      page_request = MetaInspector::Request.new(url('http://example.com'))
      expect(page_request.response.status).to eq(200)
    end

    it "contains the response headers" do
      page_request = MetaInspector::Request.new(url('http://example.com'))
      expect(page_request.response.headers)
        .to eq({"server"=>"nginx/0.7.67", "date"=>"Fri, 18 Nov 2011 21:46:46 GMT",
                    "content-type"=>"text/html", "connection"=>"keep-alive",
                    "last-modified"=>"Mon, 14 Nov 2011 16:53:18 GMT",
                    "content-length"=>"4987", "x-varnish"=>"2000423390",
                    "age"=>"0", "via"=>"1.1 varnish"})
    end
  end

  describe "content_type" do
    it "should return the correct content type of the url for html pages" do
      page_request = MetaInspector::Request.new(url('http://pagerankalert.com'))

      expect(page_request.content_type).to eq("text/html")
    end

    it "should return the correct content type of the url for non html pages" do
      image_request = MetaInspector::Request.new(url('http://pagerankalert.com/image.png'))

      expect(image_request.content_type).to eq("image/png")
    end

    it "should return nil if there is not content type present" do
      request = MetaInspector::Request.new(url('http://example.com/no-content-type'))

      expect(request.content_type).to be(nil)
    end
  end

  describe 'exception handling' do
    before(:each) do
      WebMock.allow_net_connect!
    end

    after(:each) do
      WebMock.disable_net_connect!
    end

    it "should handle connection errors" do
      expect(Net::HTTP).to receive(:new).and_raise(Faraday::ConnectionFailed)

      expect do
        MetaInspector::Request.new(url('http://example.com/fail'))
      end.to raise_error(MetaInspector::RequestError)
    end
  end

  private

  def url(initial_url)
    MetaInspector::URL.new(initial_url)
  end
end
