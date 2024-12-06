require 'pathname'
require_relative '../lib/inline_svg'

describe InlineSvg::FindsAssetPaths do
  context "when sprockets finder returns an object which supports only the pathname method" do
    it "returns fully qualified file paths from Sprockets" do
      sprockets = double('SprocketsDouble')

      expect(sprockets).to receive(:find_asset).with('some-file').
        and_return(double(pathname: Pathname('/full/path/to/some-file')))

      InlineSvg.configure do |config|
        config.asset_finder = sprockets
      end

      expect(InlineSvg::FindsAssetPaths.by_filename('some-file')).to eq Pathname('/full/path/to/some-file')
    end
  end

  context "when sprockets finder returns an object which supports only the filename method" do
    it "returns fully qualified file paths from Sprockets" do
      sprockets = double('SprocketsDouble')

      expect(sprockets).to receive(:find_asset).with('some-file').
        and_return(double(filename: Pathname('/full/path/to/some-file')))

      InlineSvg.configure do |config|
        config.asset_finder = sprockets
      end

      expect(InlineSvg::FindsAssetPaths.by_filename('some-file')).to eq Pathname('/full/path/to/some-file')
    end
  end

  context "when asset is not found" do
    it "returns nil" do
      sprockets = double('SprocketsDouble')

      expect(sprockets).to receive(:find_asset).with('some-file').and_return(nil)

      InlineSvg.configure do |config|
        config.asset_finder = sprockets
      end

      expect(InlineSvg::FindsAssetPaths.by_filename('some-file')).to be_nil
    end
  end

  context "when propshaft finder returns an object which supports only the pathname method" do
    it "returns fully qualified file paths from Propshaft" do
      propshaft = double('PropshaftDouble')

      expect(propshaft).to receive(:find_asset).with('some-file').
        and_return(double(pathname: Pathname('/full/path/to/some-file')))

      InlineSvg.configure do |config|
        config.asset_finder = propshaft
      end

      expect(InlineSvg::FindsAssetPaths.by_filename('some-file')).to eq Pathname('/full/path/to/some-file')
    end
  end

  context "when webpack finder returns an object with a relative asset path" do
    it "returns the fully qualified file path" do
      webpacker = double('WebpackerDouble')

      expect(webpacker).to receive(:find_asset).with('some-file').
        and_return(double(filename: Pathname('/full/path/to/some-file')))

      InlineSvg.configure do |config|
        config.asset_finder = webpacker
      end

      expect(InlineSvg::FindsAssetPaths.by_filename('some-file')).to eq Pathname('/full/path/to/some-file')
    end
  end

  context "when webpack finder returns an object with an absolute http asset path" do
    it "returns the fully qualified file path" do
      webpacker = double('WebpackerDouble')

      expect(webpacker).to receive(:find_asset).with('some-file').
        and_return(double(filename: Pathname('https://my-fancy-domain.test/full/path/to/some-file')))

      InlineSvg.configure do |config|
        config.asset_finder = webpacker
      end

      expect(InlineSvg::FindsAssetPaths.by_filename('some-file')).to eq Pathname('https://my-fancy-domain.test/full/path/to/some-file')
    end
  end
end
