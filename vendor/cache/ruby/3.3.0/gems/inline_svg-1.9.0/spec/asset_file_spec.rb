require_relative '../lib/inline_svg/finds_asset_paths'
require_relative '../lib/inline_svg/asset_file'

describe InlineSvg::AssetFile do
  it "reads data from a file, after qualifying a full path" do
    example_svg_path = File.expand_path(__FILE__, 'files/example.svg')
    expect(InlineSvg::FindsAssetPaths).to receive(:by_filename).with('some filename').and_return example_svg_path

    expect(InlineSvg::AssetFile.named('some filename')).to include('This is a test')
  end

  it "complains when the file cannot be read" do
    allow(InlineSvg::FindsAssetPaths).to receive(:by_filename).and_return('/this/path/does/not/exist')

    expect do
      InlineSvg::AssetFile.named('some missing file')
    end.to raise_error InlineSvg::AssetFile::FileNotFound
  end

  it "complains when the file path was not found" do
    allow(InlineSvg::FindsAssetPaths).to receive(:by_filename).and_return(nil)

    expect do
      InlineSvg::AssetFile.named('some missing file')
    end.to raise_error InlineSvg::AssetFile::FileNotFound
  end
end
