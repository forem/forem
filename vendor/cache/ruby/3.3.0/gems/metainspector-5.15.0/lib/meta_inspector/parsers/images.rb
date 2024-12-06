require 'fastimage'

module MetaInspector
  module Parsers
    class ImagesParser < Base
      delegate [:parsed, :meta, :base_url]         => :@main_parser
      delegate [:each, :length, :size, :[], :last] => :images_collection

      include Enumerable

      def initialize(main_parser, options = {})
        @download_images = options[:download_images]
        super(main_parser)
      end

      def images
        self
      end

      # Returns either the Facebook Open Graph image, twitter suggested image or
      # the largest image in the image collection
      def best
        owner_suggested || largest
      end

      # Returns the parsed image from Facebook's open graph property tags
      # Most major websites now define this property and is usually relevant
      # See doc at http://developers.facebook.com/docs/opengraph/
      # If none found, tries with Twitter image
      def owner_suggested
        suggested_img = content_of(meta['og:image']) || content_of(meta['twitter:image'])
        URL.absolutify(suggested_img, base_url, normalize: false) if suggested_img
      end

      # Returns an array of [img_url, width, height] sorted by image area (width * height)
      def with_size
        @with_size ||= begin
          img_nodes = parsed.search('//img').select{ |img_node| img_node['src'] }
          imgs_with_size = img_nodes.map do |img_node|
            [URL.absolutify(img_node['src'], base_url, normalize: false), img_node['width'], img_node['height']]
          end
          imgs_with_size.uniq! { |url, width, height| url }
          if @download_images
            imgs_with_size.map! do |url, width, height|
              width, height = FastImage.size(url) if width.nil? || height.nil?
              [url, width.to_i, height.to_i]
            end
          else
            imgs_with_size.map! do |url, width, height|
              width, height = [0, 0] if width.nil? || height.nil?
              [url, width.to_i, height.to_i]
            end
          end
          imgs_with_size.sort_by { |url, width, height| -(width.to_i * height.to_i) }
        end
      end

      # Returns the largest image from the image collection,
      # filtered for images that are more square than 10:1 or 1:10
      def largest
        @largest_image ||= begin
          imgs_with_size = with_size.dup
          imgs_with_size.keep_if do |url, width, height|
            ratio = width.to_f / height.to_f
            ratio > 0.1 && ratio < 10
          end
          url, width, height = imgs_with_size.first
          url
        end
      end

      # Return favicon url if exist
      def favicon
        query = '//link[@rel="icon" or contains(@rel, "shortcut")]'
        value = parsed.xpath(query)[0].attributes['href'].value
        @favicon ||= URL.absolutify(value, base_url, normalize: false)
      rescue
        nil
      end

      private

      def images_collection
        @images_collection ||= absolutified_images
      end

      def absolutified_images
        parsed_images.map { |i| URL.absolutify(i, base_url, normalize: false) }
      end

      def parsed_images
        cleanup(parsed.search('//img/@src'))
      end

      def content_of(content)
        return nil if content.nil? || content.empty?
        content
      end
    end
  end
end
