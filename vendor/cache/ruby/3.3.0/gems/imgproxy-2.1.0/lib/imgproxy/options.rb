require "imgproxy/trim_array"
require "imgproxy/options_casters/string"
require "imgproxy/options_casters/integer"
require "imgproxy/options_casters/float"
require "imgproxy/options_casters/bool"
require "imgproxy/options_casters/array"
require "imgproxy/options_casters/base64"
require "imgproxy/options_casters/resize"
require "imgproxy/options_casters/size"
require "imgproxy/options_casters/extend"
require "imgproxy/options_casters/gravity"
require "imgproxy/options_casters/crop"
require "imgproxy/options_casters/trim"
require "imgproxy/options_casters/adjust"
require "imgproxy/options_casters/watermark"
require "imgproxy/options_casters/jpeg_options"
require "imgproxy/options_casters/png_options"
require "imgproxy/options_casters/gif_options"

module Imgproxy
  # Formats and regroups processing options
  class Options < Hash
    using TrimArray

    CASTERS = {
      resize:                 Imgproxy::OptionsCasters::Resize,
      size:                   Imgproxy::OptionsCasters::Size,
      resizing_type:          Imgproxy::OptionsCasters::String,
      resizing_algorithm:     Imgproxy::OptionsCasters::String,
      width:                  Imgproxy::OptionsCasters::Integer,
      height:                 Imgproxy::OptionsCasters::Integer,
      dpr:                    Imgproxy::OptionsCasters::Float,
      enlarge:                Imgproxy::OptionsCasters::Bool,
      extend:                 Imgproxy::OptionsCasters::Extend,
      gravity:                Imgproxy::OptionsCasters::Gravity,
      crop:                   Imgproxy::OptionsCasters::Crop,
      padding:                Imgproxy::OptionsCasters::Array,
      trim:                   Imgproxy::OptionsCasters::Trim,
      rotate:                 Imgproxy::OptionsCasters::Integer,
      quality:                Imgproxy::OptionsCasters::Integer,
      max_bytes:              Imgproxy::OptionsCasters::Integer,
      background:             Imgproxy::OptionsCasters::Array,
      background_alpha:       Imgproxy::OptionsCasters::Float,
      adjust:                 Imgproxy::OptionsCasters::Adjust,
      brightness:             Imgproxy::OptionsCasters::Integer,
      contrast:               Imgproxy::OptionsCasters::Float,
      saturation:             Imgproxy::OptionsCasters::Float,
      blur:                   Imgproxy::OptionsCasters::Float,
      sharpen:                Imgproxy::OptionsCasters::Float,
      pixelate:               Imgproxy::OptionsCasters::Integer,
      unsharpening:           Imgproxy::OptionsCasters::String,
      watermark:              Imgproxy::OptionsCasters::Watermark,
      watermark_url:          Imgproxy::OptionsCasters::Base64,
      style:                  Imgproxy::OptionsCasters::Base64,
      jpeg_options:           Imgproxy::OptionsCasters::JpegOptions,
      png_options:            Imgproxy::OptionsCasters::PngOptions,
      gif_options:            Imgproxy::OptionsCasters::GifOptions,
      page:                   Imgproxy::OptionsCasters::Integer,
      video_thumbnail_second: Imgproxy::OptionsCasters::Integer,
      preset:                 Imgproxy::OptionsCasters::Array,
      cachebuster:            Imgproxy::OptionsCasters::String,
      strip_metadata:         Imgproxy::OptionsCasters::Bool,
      strip_color_profile:    Imgproxy::OptionsCasters::Bool,
      auto_rotate:            Imgproxy::OptionsCasters::Bool,
      filename:               Imgproxy::OptionsCasters::String,
      format:                 Imgproxy::OptionsCasters::String,
      return_attachment:      Imgproxy::OptionsCasters::Bool,
      expires:                Imgproxy::OptionsCasters::Integer,
    }.freeze

    META = %i[size resize adjust].freeze

    # @param options [Hash] raw processing options
    def initialize(options)
      super()

      # Options order hack: initialize known and meta options with nil value to preserve order
      CASTERS.each_key { |n| self[n] = nil if options.key?(n) || META.include?(n) }

      options.each do |name, value|
        caster = CASTERS[name]
        self[name] = caster ? caster.cast(value) : unwrap_hash(value)
      end

      group_resizing_opts
      group_adjust_opts

      compact!
    end

    private

    def unwrap_hash(raw)
      return raw unless raw.is_a?(Hash)

      raw.flat_map do |_key, val|
        unwrap_hash(val)
      end
    end

    def group_resizing_opts
      return unless self[:width] && self[:height] && !self[:size] && !self[:resize]

      self[:size] = extract_and_trim_nils(:width, :height, :enlarge, :extend)
      self[:resize] = [delete(:resizing_type), *delete(:size)] if self[:resizing_type]
    end

    def group_adjust_opts
      return if self[:adjust]
      return unless values_at(:brightness, :contrast, :saturation).count { |o| o } > 1

      self[:adjust] = extract_and_trim_nils(:brightness, :contrast, :saturation)
    end

    def extract_and_trim_nils(*keys)
      keys.map { |k| delete(k) }.trim!
    end
  end
end
