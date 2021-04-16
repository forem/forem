require "rails_helper"

RSpec.describe Users::SafeRemoteProfileImageUrl, type: :service do
  it "returns the url if passed for proper URLs" do
    url = "https://image.com/image.png"
    expect(described_class.call(url)).to eq(url)
  end

  it "returns fallback image if passed nil" do
    expect(described_class.call(nil)).to start_with("https://emojipedia-us.s3")
  end

  it "returns fallback image if passed blank" do
    expect(described_class.call("")).to start_with("https://emojipedia-us.s3")
  end

  it "returns fallback image if passed non-URL" do
    expect(described_class.call("image")).to start_with("https://emojipedia-us.s3")
  end
end
