require_relative '../lib/inline_svg'

describe InlineSvg::PropshaftAssetFinder do
  context "when the file is not found" do
    it "returns nil" do
      stub_const('Rails', double('Rails').as_null_object)
      expect(::Rails.application.assets.load_path).to receive(:find).with('some-file').and_return(nil)

      expect(InlineSvg::PropshaftAssetFinder.find_asset('some-file').pathname).to be_nil
    end
  end

  context "when the file is found" do
    it "returns fully qualified file paths from Propshaft" do
      stub_const('Rails', double('Rails').as_null_object)
      asset = double('Asset')
      expect(asset).to receive(:path).and_return(Pathname.new('/full/path/to/some-file'))
      expect(::Rails.application.assets.load_path).to receive(:find).with('some-file').and_return(asset)

      expect(InlineSvg::PropshaftAssetFinder.find_asset('some-file').pathname).to eq Pathname('/full/path/to/some-file')
    end
  end
end
