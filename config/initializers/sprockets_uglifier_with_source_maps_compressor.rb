require "sprockets/digest_utils"
require "sprockets/uglifier_compressor"

module Sprockets
  class UglifierWithSourceMapsCompressor < Sprockets::UglifierCompressor
    def call(input)
      data = input.fetch(:data) # Non-Uglified contents of the JS file
      name = input.fetch(:name) # name of the to-be-compressed JS file.

      @uglifier ||= Autoload::Uglifier.new(@options.merge({ harmony: true }))
      compressed_data, sourcemap_json = @uglifier.compile_with_map(input[:data])

      # Update source map according to the version 3 spec: https://sourcemaps.info/spec.html
      sourcemap                   = JSON.parse(sourcemap_json)
      sourcemap["sources"]        = ["#{name}.js"]
      sourcemap["sourceRoot"]     = ::Rails.application.config.assets.prefix
      sourcemap["sourcesContent"] = [data]
      sourcemap_json              = sourcemap.to_json

      sourcemap_filename = File.join(
        ::Rails.application.config.assets.prefix,
        "#{name}-#{digest(sourcemap_json)}.js.map",
      )
      # rubocop:disable Rails/RootPathnameMethods
      sourcemap_path = File.join(::Rails.public_path, sourcemap_filename)
      # rubocop:enable Rails/RootPathnameMethods
      sourcemap_url  = filename_to_url(sourcemap_filename)

      FileUtils.mkdir_p File.dirname(sourcemap_path)
      File.write(sourcemap_path, sourcemap_json)

      # Add the source map URL to the compressed JS file.
      compressed_data.concat "\n//# sourceMappingURL=#{sourcemap_url}\n"
    end

    def filename_to_url(filename)
      url_root = ::Rails.application.config.assets.source_maps_domain
      File.join url_root.to_s, filename
    end

    def digest(io)
      Sprockets::DigestUtils.pack_hexdigest Sprockets::DigestUtils.digest(io)
    end
  end
end

Sprockets.register_compressor(
  "application/javascript",
  :uglify_with_source_maps,
  Sprockets::UglifierWithSourceMapsCompressor,
)
