require 'spec_helper'

describe Buffer::Client do
  let(:id) { "5160746d54f04a5e3a00000f" }

  subject do
    Buffer::Client.new("some_token")
  end

  describe "#initialize" do
    it "allows a token to be set and retrieved" do
      subject.access_token.should eq("some_token")
    end
  end

  describe "#connection" do
    it "assigns the connection instance variable" do
      subject.connection.should eq(subject.instance_variable_get(:@connection))
    end
  end

  describe "#info" do
    before do
      stub_request(:get, "#{base_path}/info/configuration.json?access_token=some_token").
        to_return(fixture("info.txt"))
    end

    it "connects to the correct endpoint" do
      subject.info
    end

    it "retrieves the correct name" do
      subject.info.services.twitter.types.profile.name.should eq("Twitter")
    end
  end
end
