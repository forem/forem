require "rails_helper"

RSpec.describe Images::SafeRemoteProfileImageUrl, type: :service do
  it "returns the url if passed for proper URLs" do
    url = "https://image.com/image.png"
    expect(described_class.call(url)).to eq(url)
  end

  it "returns fallback image if passed nil" do
    expect(described_class.call(nil)).to be_a(File)
  end

  it "returns fallback image if passed blank" do
    expect(described_class.call("")).to be_a(File)
  end

  it "returns fallback image if passed non-URL" do
    expect(described_class.call("image")).to be_a(File)
  end

  it "returns a secure HTTPS image link if pass a regular HTTP link" do
    url = "http://image.com/image.jpg"
    expect(described_class.call(url)).to eq "https://image.com/image.jpg"
  end
end
