require 'spec_helper'

describe Buffer::Client::User do
  let(:id) { "5160746d54f04a5e3a00000f" }

  subject do
    Buffer::Client.new("some_token")
  end

  describe "#user_info" do
    let(:rash) { subject.user_info }

    before(:each) do
      url = "#{ base_path }/user.json"
      stub_with_to_return(:get, url, "user_authenticated.txt")
    end

    it "returns a Rash object" do
      rash.class.should eq(Buffer::UserInfo)
    end

    it "provides an accessor for plan" do
      rash.plan.should eq("free")
    end
  end
end
