require "minitest_helper"

describe Fog::XML::Connection do
  before do
    @connection = Fog::XML::Connection.new("http://localhost")
  end

  after do
    Excon.stubs.clear
  end

  it "responds to #request" do
    assert_respond_to @connection, :request
  end

  describe "when request is passed a parser" do
    it "returns the body after parsing" do
      @parser = Fog::ToHashDocument.new
      Excon.stub({}, { :status => 200, :body => "<xml></xml>" })
      response = @connection.request(:parser => @parser, :mock => true)
      assert_equal({ :xml => "" }, response.body)
    end
  end

  describe "when request excludes a parser" do
    it "returns the response body without change" do
      Excon.stub({}, { :status => 200, :body => "<xml></xml>" })
      response = @connection.request(:mock => true)
      assert_equal("<xml></xml>", response.body)
    end
  end
end
