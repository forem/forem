require "pathname"

# Naive fallback asset finder for when sprockets >= 3.0 &&
# config.assets.precompile = false
# Thanks to @ryanswood for the original code:
# https://github.com/jamesmartin/inline_svg/commit/661bbb3bef7d1b4bd6ccd63f5f018305797b9509
module InlineSvg
  class StaticAssetFinder
    def self.find_asset(filename)
      new(filename)
    end

    def initialize(filename)
      @filename = filename
    end

    def pathname
      if ::Rails.application.config.assets.compile
        asset = ::Rails.application.assets[@filename]
        Pathname.new(asset.filename) if asset.present?
      else
        manifest = ::Rails.application.assets_manifest
        asset_path = manifest.assets[@filename]
        unless asset_path.nil?
          ::Rails.root.join(manifest.directory, asset_path)
        end
      end
    end
  end
end
