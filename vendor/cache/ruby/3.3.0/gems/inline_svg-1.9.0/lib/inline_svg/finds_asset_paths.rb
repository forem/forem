module InlineSvg
  class FindsAssetPaths
    def self.by_filename(filename)
      asset = configured_asset_finder.find_asset(filename)
      asset.try(:pathname) || asset.try(:filename)
    end

    def self.configured_asset_finder
      Thread.current[:inline_svg_asset_finder] || InlineSvg.configuration.asset_finder
    end
  end
end
