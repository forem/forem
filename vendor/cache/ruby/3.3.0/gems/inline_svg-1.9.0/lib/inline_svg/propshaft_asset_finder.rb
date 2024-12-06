module InlineSvg
  class PropshaftAssetFinder
    def self.find_asset(filename)
      new(filename)
    end

    def initialize(filename)
      @filename = filename
    end

    def pathname
      asset_path = ::Rails.application.assets.load_path.find(@filename)
      asset_path.path unless asset_path.nil?
    end
  end
end
