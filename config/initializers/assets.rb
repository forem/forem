# Be sure to restart your server when you modify this file.

# Skip redundant Terser re-minification for assets in app/assets/builds
# (already bundled and minified by esbuild), pre-minified *.min.js vendor assets,
# and internal tech-admin engine bundles (blazer, pghero).
module EsbuildSkippingTerserCompressor
  BUILDS_PATH = Rails.root.join("app/assets/builds").to_s.freeze
  SKIPPED_ENGINE_ASSET_PATTERNS = %w[
    /blazer/application
    /pghero/application
  ].freeze

  CACHE_KEY_VERSION = "v2".freeze

  def self.cache_key
    "EsbuildSkippingTerserCompressor:#{CACHE_KEY_VERSION}:#{Terser::Compressor.cache_key}"
  end

  def self.call(input)
    return if prebuilt_asset?(input)

    Terser::Compressor.call(input)
  end

  def self.prebuilt_asset?(input)
    load_path = input[:load_path].to_s
    filename = input[:filename].to_s
    name = input[:name].to_s

    load_path == BUILDS_PATH ||
      load_path.end_with?("/app/assets/builds") ||
      filename.start_with?("#{BUILDS_PATH}/") ||
      filename.include?("/app/assets/builds/") ||
      filename.end_with?(".min.js") ||
      name == "blazer/application" ||
      name == "pghero/application" ||
      SKIPPED_ENGINE_ASSET_PATTERNS.any? { |pattern| filename.include?(pattern) }
  end
end

# See: https://github.com/sass/sassc-ruby/issues/197
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
  env.register_compressor "application/javascript", :terser_skip_builds, EsbuildSkippingTerserCompressor
end

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.1"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")

Rails.application.config.assets.paths << Rails.root.join("app/assets/xml")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w[markdown-it.min.js markdownlint-browser.min.js]
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
