require "rails_helper"

RSpec.describe ForemInstance, type: :model do
  describe "deployed_at" do
    it "sets the RELEASE_FOOTPRINT if present" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("A deploy date")
      stub_const("ENV", ENV.to_h.merge("HEROKU_RELEASE_CREATED_AT" => ""))
      expect(described_class.deployed_at).to be(ApplicationConfig["RELEASE_FOOTPRINT"])
    end

    it "sets the HEROKU_RELEASE_CREATED_AT if the RELEASE_FOOTPRINT is not present" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("")
      stub_const("ENV", ENV.to_h.merge("HEROKU_RELEASE_CREATED_AT" => "A deploy date set on Heroku"))
      described_class.instance_variable_set(:@deployed_at, nil)
      expect(described_class.deployed_at).to be(ENV["HEROKU_RELEASE_CREATED_AT"])
    end
  end

  describe "latest_commit_id" do
    it "sets the FOREM_BUILD_SHA if present" do
      allow(ApplicationConfig).to receive(:[]).with("FOREM_BUILD_SHA").and_return("A commit id")
      stub_const("ENV", ENV.to_h.merge("HEROKU_SLUG_COMMIT" => ""))
      expect(described_class.latest_commit_id).to be(ApplicationConfig["FOREM_BUILD_SHA"])
    end

    it "sets the HEROKU_RELEASE_CREATED_AT if the RELEASE_FOOTPRINT is not present" do
      allow(ApplicationConfig).to receive(:[]).with("FOREM_BUILD_SHA").and_return("")
      stub_const("ENV", ENV.to_h.merge("HEROKU_SLUG_COMMIT" => "A Commit ID set from Heroku"))
      described_class.instance_variable_set(:@latest_commit_id, nil)
      expect(described_class.latest_commit_id).to be(ENV["HEROKU_SLUG_COMMIT"])
    end
  end
end
