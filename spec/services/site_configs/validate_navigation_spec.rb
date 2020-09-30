require "rails_helper"

RSpec.describe SiteConfigs::ValidateNavigation, type: :service do
  let(:valid_link) do
    { name: "Test", url: "http://examle.com", icon: "<svg ...>" }
  end

  let(:invalid_name) do
    { name: "", url: "http://examle.com", icon: "<svg ...>" }
  end

  let(:invalid_url) do
    { name: "Test", url: "test", icon: "<svg ...>" }
  end

  let(:invalid_icon) do
    { name: "Test", url: "http://examle.com", icon: "test.png" }
  end

  let(:all_invalid) do
    { name: "", url: "test", icon: "test.png" }
  end

  it "returns success to be true when a link is valid" do
    links = [valid_link]
    result = described_class.call(links)
    expect(result.success?).to be true
  end

  it "returns the errors with an index" do
    links = [valid_link, invalid_name, invalid_url, invalid_icon, all_invalid]
    expected_errors = {
      1 => ["Name can't be blank"],
      2 => ["Url is invalid"],
      3 => ["Icon is invalid"],
      4 => ["Name can't be blank", "Url is invalid", "Icon is invalid"]
    }

    result = described_class.call(links)
    expect(result.success?).to be false
    expect(result.errors).to eq(expected_errors)
  end
end
