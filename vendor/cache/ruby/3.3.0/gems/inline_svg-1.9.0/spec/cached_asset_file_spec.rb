# frozen_string_literal: true
require 'pathname'
require_relative '../lib/inline_svg'

describe InlineSvg::CachedAssetFile do
  let(:fixture_path) { Pathname.new(File.expand_path("../files/static_assets", __FILE__)) }

  it "loads assets under configured paths" do
    known_document = File.read(fixture_path.join("assets0", "known-document.svg"))

    asset_loader = InlineSvg::CachedAssetFile.new(paths: fixture_path.join("assets0"))

    expect(asset_loader.named("known-document.svg")).to eq(known_document)
  end

  it "does not include assets outside of configured paths" do
    asset_loader = InlineSvg::CachedAssetFile.new(paths: fixture_path.join("assets0"))

    expect(fixture_path.join("assets1", "other-document.svg")).to be_file
    expect do
      asset_loader.named("other-document.svg")
    end.to raise_error InlineSvg::AssetFile::FileNotFound
  end

  it "differentiates two files with the same name" do
    known_document_0 = File.read(fixture_path.join("assets0", "known-document.svg"))
    known_document_1 = File.read(fixture_path.join("assets1", "known-document.svg"))

    expect(known_document_0).not_to eq(known_document_1)

    asset_loader = InlineSvg::CachedAssetFile.new(paths: fixture_path)

    expect(known_document_0).to eq(asset_loader.named("assets0/known-document.svg"))
    expect(known_document_1).to eq(asset_loader.named("assets1/known-document.svg"))
  end

  it "chooses the closest exact matching file when similar files exist in the same path" do
    known_document = File.read(fixture_path.join("assets0", "known-document.svg"))
    known_document_2 = File.read(fixture_path.join("assets0", "known-document-two.svg"))

    expect(known_document).not_to eq(known_document_2)

    asset_loader = InlineSvg::CachedAssetFile.new(paths: fixture_path.join("assets0"), filters: /\.svg/)

    expect(asset_loader.named("known-document")).to eq(known_document)
    expect(asset_loader.named("known-document-two")).to eq(known_document_2)
  end

  it "filters wanted files by simple string matching" do
    known_document_0 = File.read(fixture_path.join("assets0", "known-document.svg"))
    known_document_1 = File.read(fixture_path.join("assets1", "known-document.svg"))

    asset_loader = InlineSvg::CachedAssetFile.new(paths: fixture_path, filters: "assets1")

    expect do
      asset_loader.named("assets0/known-document.svg")
    end.to raise_error InlineSvg::AssetFile::FileNotFound

    expect(known_document_1).to eq(asset_loader.named("assets1/known-document.svg"))
  end

  it "filters wanted files by regex matching" do
    known_document_1 = File.read(fixture_path.join("assets1", "known-document.svg"))

    asset_loader = InlineSvg::CachedAssetFile.new(paths: fixture_path, filters: ["assets1", /\.svg/])

    expect do
      asset_loader.named("assets1/some-file.txt")
    end.to raise_error InlineSvg::AssetFile::FileNotFound

    expect(known_document_1).to eq(asset_loader.named("assets1/known-document.svg"))
  end
end
