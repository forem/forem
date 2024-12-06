module InlineSvg
  class AssetFile
    class FileNotFound < IOError; end
    UNREADABLE_PATH = ''

    def self.named(filename)
      asset_path = FindsAssetPaths.by_filename(filename)
      File.read(asset_path || UNREADABLE_PATH)
    rescue Errno::ENOENT
      raise FileNotFound.new("Asset not found: #{asset_path}")
    end
  end
end
