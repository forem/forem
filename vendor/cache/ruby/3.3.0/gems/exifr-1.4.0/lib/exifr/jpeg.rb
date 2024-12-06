# Copyright (c) 2006-2020 - R.W. van 't Veer

require 'exifr'
require 'exifr/tiff'
require 'stringio'
require 'delegate'

module EXIFR
  # = JPEG decoder
  #
  # == Examples
  #   EXIFR::JPEG.new('IMG_3422.JPG').width         # -> 2272
  #   EXIFR::JPEG.new('IMG_3422.JPG').exif.model    # -> "Canon PowerShot G3"
  class JPEG
    # image height
    attr_reader :height
    # image width
    attr_reader :width
    # number of bits per ??
    attr_reader :bits # :nodoc:
    # comment; a string if one comment found, an array if more,
    # otherwise <tt>nil</tt>
    attr_reader :comment
    # EXIF data if available
    attr_reader :exif
    # raw EXIF data
    attr_reader :exif_data # :nodoc:
    # raw APP1 frames
    attr_reader :app1s

    # +file+ is a filename or an IO object.  Hint: use StringIO when working with slurped data like blobs.
    def initialize(file, load_thumbnails: true)
      if file.kind_of? String
        File.open(file, 'rb') { |io| examine(io, load_thumbnails: load_thumbnails) }
      else
        examine(file.dup, load_thumbnails: load_thumbnails)
      end
    end

    # Returns +true+ when EXIF data is available.
    def exif?
      !exif.nil?
    end

    # Return thumbnail data when available.
    def thumbnail
      defined?(@exif) && @exif && @exif.jpeg_thumbnails && @exif.jpeg_thumbnails.first
    end

    # Get a hash presentation of the image.
    def to_hash
      h = {:width => width, :height => height, :bits => bits, :comment => comment}
      h.merge!(exif) if exif?
      h
    end

    # Dispatch to EXIF.  When no EXIF data is available but the
    # +method+ does exist for EXIF data +nil+ will be returned.
    def method_missing(method, *args)
      super unless args.empty?
      super unless methods.include?(method)
      @exif.send method if defined?(@exif) && @exif
    end

    def respond_to?(method, include_all = false) # :nodoc:
      super || methods.include?(method) || (include_all && private_methods.include?(method))
    end

    def methods(regular=true) # :nodoc:
      if regular
        super + TIFF::TAGS << :gps
      else
        super
      end
    end

    class << self
      alias instance_methods_without_jpeg_extras instance_methods
      def instance_methods(include_super = true) # :nodoc:
        instance_methods_without_jpeg_extras(include_super) + TIFF::TAGS << :gps
      end
    end

  private

    class Reader < SimpleDelegator
      def readbyte; readchar; end unless File.method_defined?(:readbyte)
      def readint; (readbyte << 8) + readbyte; end
      def readframe; read(readint - 2); end
      def readsof; [readint, readbyte, readint, readint, readbyte]; end
      def next
        c = readbyte while c != 0xFF
        c = readbyte while c == 0xFF
        c
      end
    end

    def examine(io, load_thumbnails: true)
      io = Reader.new(io)

      unless io.getbyte == 0xFF && io.getbyte == 0xD8 # SOI
        raise MalformedJPEG, "no start of image marker found"
      end

      @app1s = []
      while marker = io.next
        case marker
          when 0xC0..0xC3, 0xC5..0xC7, 0xC9..0xCB, 0xCD..0xCF # SOF markers
            length, @bits, @height, @width, components = io.readsof
            unless length == 8 + components * 3
              raise MalformedJPEG, "frame length does not match number of components"
            end
          when 0xD9, 0xDA;  break # EOI, SOS
          when 0xFE;        (@comment ||= []) << io.readframe # COM
          when 0xE1;        @app1s << io.readframe # APP1, may contain EXIF tag
          else              io.readframe # ignore frame
        end
      end

      @comment = @comment.first if defined?(@comment) && @comment && @comment.size == 1

      if app1 = @app1s.find { |d| d[0..5] == "Exif\0\0" }
        @exif_data = app1[6..-1]
        @exif = TIFF.new(StringIO.new(@exif_data), load_thumbnails: load_thumbnails)
      end
    end
  end
end
