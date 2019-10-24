require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#community_qualified_name" do
    it "equals to the full qualified community name" do
      expected_name = "The #{ApplicationConfig['COMMUNITY_NAME']} Community"
      expect(helper.community_qualified_name).to eq(expected_name)
    end
  end

  describe "#beautified_url" do
    it "strips the protocol" do
      expect(helper.beautified_url("https://github.com")).to eq("github.com")
    end

    it "strips params" do
      expect(helper.beautified_url("https://github.com?a=3")).to eq("github.com")
    end

    it "strips the last forward slash" do
      expect(helper.beautified_url("https://github.com/")).to eq("github.com")
    end

    it "does not strip the path" do
      expect(helper.beautified_url("https://github.com/rails")).to eq("github.com/rails")
    end
  end

  describe "#cloudinary" do
    before do
      stub_const("BASE_URL", "https://res.cloudinary.com/TEST-CLOUD/image/fetch")
    end

    it "delivers the cloudinary url with reasonable default transforms" do
      actual = helper.cloudinary("banana.jpg")

      ["c_scale", "fl_progressive", "q_auto", "f_auto", "banana.jpg", BASE_URL].each do |setting|
        expect(actual).to include(setting)
      end

      # Also it should be a valid URL
      expect(actual).to match(URI.regexp(["https"]))
    end

    it "can specify an image width" do
      actual = helper.cloudinary("banana.jpg", width: 400)

      ["w_400", "c_scale", "fl_progressive", "q_auto", "f_auto", "banana.jpg", BASE_URL].each do |setting|
        expect(actual).to include(setting)
      end

      # Also it should be a valid URL
      expect(actual).to match(URI.regexp(["https"]))
    end

    it "returns a blank image if the url is blank" do
      blank_image_url = "https://pbs.twimg.com/profile_images/481625927911092224/iAVNQXjn_normal.jpeg"
      actual = helper.cloudinary("")

      ["c_scale", "fl_progressive", "q_1", "f_auto", blank_image_url, BASE_URL].each do |setting|
        expect(actual).to include(setting)
      end

      # Also it should be a valid URL
      expect(actual).to match(URI.regexp(["https"]))
    end
  end
end
