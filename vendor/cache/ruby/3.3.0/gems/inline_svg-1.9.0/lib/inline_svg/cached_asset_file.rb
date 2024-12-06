# frozen_string_literal: true

module InlineSvg
  class CachedAssetFile
    attr_reader :assets, :filters, :paths

    # For each of the given paths, recursively reads each asset and stores its
    # contents alongside the full path to the asset.
    #
    # paths   - One or more String representing directories on disk to search
    #           for asset files. Note: paths are searched recursively.
    # filters - One or more Strings/Regexps to match assets against. Only
    #           assets matching all filters will be cached and available to load.
    #           Note: Specifying no filters will cache every file found in
    #           paths.
    #
    def initialize(paths: [], filters: [])
      @paths = Array(paths).compact.map { |p| Pathname.new(p) }
      @filters = Array(filters).map { |f| Regexp.new(f) }
      @assets = @paths.reduce({}) { |assets, p| assets.merge(read_assets(assets, p)) }
      @sorted_asset_keys = assets.keys.sort { |a, b| a.size <=> b.size }
    end

    # Public: Finds the named asset and returns the contents as a string.
    #
    # asset_name  - A string representing the name of the asset to load
    #
    # Returns: A String or raises InlineSvg::AssetFile::FileNotFound error
    def named(asset_name)
      assets[key_for_asset(asset_name)] or
        raise InlineSvg::AssetFile::FileNotFound.new("Asset not found: #{asset_name}")
    end

    private
    # Internal: Finds the key for a given asset name (using a Regex). In the
    # event of an ambiguous asset_name matching multiple assets, this method
    # ranks the matches by their full file path, choosing the shortest (most
    # exact) match over all others.
    #
    # Returns a String representing the key for the named asset or nil if there
    # is no match.
    def key_for_asset(asset_name)
      @sorted_asset_keys.find { |k| k.include?(asset_name) }
    end

    # Internal: Recursively descends through current_paths reading each file it
    # finds and adding them to the accumulator if the fullpath of the file
    # matches all configured filters.
    #
    # acc     - Hash representing the accumulated assets keyed by full path
    # paths   - Pathname representing the current node in the directory
    #           structure to consider
    #
    # Returns a Hash containing the contents of each asset, keyed by fullpath
    # to the asset.
    def read_assets(acc, paths)
      paths.each_child do |child|
        if child.directory?
          read_assets(acc, child)
        elsif child.readable_real?
          acc[child.to_s] = File.read(child) if matches_all_filters?(child)
        end
      end
      acc
    end

    def matches_all_filters?(path)
      filters.all? { |f| f.match(path.to_s) }
    end
  end
end
