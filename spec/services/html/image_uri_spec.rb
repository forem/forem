require "rails_helper"

RSpec.describe Html::ImageUri, type: :service do
  let(:camo) { "https://camo.githubusercontent.com/64b9f7c7c5f41ec22113b61235256435cd61779a0554b0595b88b6011f94c60b/68747470733a2f2f696d672e736869656c64732e696f2f6769746875622f636f6d6d69742d61637469766974792f772f666f72656d2f666f72656d" }
  let(:badge) { "https://github.com/forem/forem/actions/workflows/ci-cd.yml/badge.svg?branch=depfu/update/sterile-1.0.24" }
  let(:giphy) { "https://media.giphy.com/media/3ow0TN2M8TH2aAn67F/giphy.gif" }
  let(:other) { "https://image.com/image.jpg" }

  it "can detect camo.github hosted image" do
    image = described_class.new(camo)
    expect(image).to be_github_camo_user_content

    image = described_class.new(badge)
    expect(image).not_to be_github_camo_user_content

    image = described_class.new(giphy)
    expect(image).not_to be_github_camo_user_content

    image = described_class.new(other)
    expect(image).not_to be_github_camo_user_content
  end

  it "can detect github hosted badge" do
    image = described_class.new(badge)
    expect(image).to be_github_badge

    image = described_class.new(camo)
    expect(image).not_to be_github_badge

    image = described_class.new(giphy)
    expect(image).not_to be_github_badge

    image = described_class.new(other)
    expect(image).not_to be_github_badge
  end

  it "can detect first party assets" do
    allow(Settings::General).to receive(:app_domain).and_return("dev.to")
    allow(ActionController::Base).to receive(:asset_host).and_return("https://assets.dev.to")

    app_svg = described_class.new("https://dev.to/some.svg")
    expect(app_svg).to be_first_party_asset

    asset_svg = described_class.new("https://assets.dev.to/assets/github-logo-123.svg")
    expect(asset_svg).to be_first_party_asset

    relative_svg = described_class.new("/assets/github-logo-123.svg")
    expect(relative_svg).to be_first_party_asset

    external_svg = described_class.new("https://example.com/some.svg")
    expect(external_svg).not_to be_first_party_asset

    app_png = described_class.new("https://dev.to/some.png")
    expect(app_png).to be_first_party_asset

    external_png = described_class.new("https://example.com/some.png")
    expect(external_png).not_to be_first_party_asset
  end
end
