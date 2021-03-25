require 'spec_helper'

describe Buffer::Client do
  describe "#link" do
    let(:client) { Buffer::Client.new("some_token") }
    let(:url) { %q{http://bufferapp.com} }

    before do
      stub_request(:get, "#{ base_path }/links/shares.json?#{ access_token_param }&url=http://bufferapp.com").
      to_return(fixture('link.txt'))
    end

    it "connects to the correct endpoint" do
      client.link({url: url})
    end

    it "parses the shares of a link" do
      client.link({url: url}).shares.should eq(47348)
    end

  end
end
