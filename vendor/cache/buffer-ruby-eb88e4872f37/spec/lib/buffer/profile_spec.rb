require 'spec_helper'

describe Buffer::Client::Profile do
  let(:id) { "5160746d54f04a5e3a00000f" }

  subject do
    Buffer::Client.new("some_token")
  end

  describe "#profiles" do
    let(:rash) { Buffer::Client.new("some_token").profiles }

    before(:each) do
      url = "#{ base_path }/profiles.json"
      stub_with_to_return(:get, url, 'profile_authenticated.txt')
    end

    it "makes the correct url request" do
      subject.profiles
    end

    it "returns a Rash collection object" do
      rash[0].class.should eq(Buffer::Profile)
    end

    it "provides an accessor for plan" do
      rash[0].service.should eq("twitter")
    end
  end

  describe "#profile_by_id" do
    let(:id) { "5160746d54f04a5e3a00000f" }
    before(:each) do
      url = "#{base_path}/profiles/#{id}.json"
      fixture_name = "profiles_by_id.txt"
      stub_with_to_return(:get, url, fixture_name)
    end

    let(:rash) { Buffer::Client.new("some_token").profile_by_id(id) }

    it "returns a rash collection" do
      rash.class.should eq(Buffer::Profile)
    end

    it "accesses formatted service" do
      rash.formatted_service.should eq("Twitter")
    end
  end

  describe "#schedules_by_profile_id" do
    before(:each) do
      url = "#{base_path}/profiles/#{id}/schedules.json"
      fixture_name = 'profile_schedules_by_id.txt'
      stub_with_to_return(:get, url, fixture_name)
    end

    let(:rash) { Buffer::Client.new("some_token").schedules_by_profile_id(id) }

    it "returns a rash collection" do
      rash[0].class.should eq(Buffer::Schedule)
    end

    it "accesses days" do
      expect(rash[0].days).to include("mon")
    end

    it "accesses times" do
      expect(rash[0].times).to include("06:13")
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
