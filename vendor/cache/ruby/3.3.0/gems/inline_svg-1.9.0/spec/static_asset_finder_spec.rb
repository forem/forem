require_relative '../lib/inline_svg'

describe InlineSvg::StaticAssetFinder do
  context "when the file is not found" do
    it "returns nil" do
      stub_const('Rails', double('Rails').as_null_object)
      expect(::Rails.application.config.assets).to receive(:compile).and_return(true)

      expect(described_class.find_asset('some-file').pathname).to be_nil
    end
  end

  context "when the file is found" do
    it "returns fully qualified file path from Sprockets" do
      stub_const('Rails', double('Rails').as_null_object)
      expect(::Rails.application.config.assets).to receive(:compile).and_return(true)
      pathname = Pathname.new('/full/path/to/some-file')
      asset = double('Asset')
      expect(asset).to receive(:filename).and_return(pathname)
      expect(::Rails.application.assets).to receive(:[]).with('some-file').and_return(asset)

      expect(described_class.find_asset('some-file').pathname).to eq(pathname)
    end
  end
end
