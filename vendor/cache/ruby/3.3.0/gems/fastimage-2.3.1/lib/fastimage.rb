# frozen_string_literal: true
# coding: ASCII-8BIT

# FastImage finds the size or type of an image given its uri.
# It is careful to only fetch and parse as much of the image as is needed to determine the result.
# It does this by using a feature of Net::HTTP that yields strings from the resource being fetched
# as soon as the packets arrive.
#
# No external libraries such as ImageMagick are used here, this is a very lightweight solution to
# finding image information.
#
# FastImage knows about GIF, JPEG, BMP, TIFF, ICO, CUR, PNG, PSD, SVG and WEBP files.
#
# FastImage can also read files from the local filesystem by supplying the path instead of a uri.
# In this case FastImage reads the file in chunks of 256 bytes until
# it has enough. This is possibly a useful bandwidth-saving feature if the file is on a network
# attached disk rather than truly local.
#
# FastImage will automatically read from any object that responds to :read - for
# instance an IO object if that is passed instead of a URI.
#
# FastImage will follow up to 4 HTTP redirects to get the image.
#
# FastImage also provides a reader for the content length header provided in HTTP.
# This may be useful to assess the file size of an image, but do not rely on it exclusively -
# it will not be present in chunked responses for instance.
#
# FastImage accepts additional HTTP headers. This can be used to set a user agent
# or referrer which some servers require. Pass an :http_header argument to specify headers,
# e.g., :http_header => {'User-Agent' => 'Fake Browser'}.
#
# FastImage can give you information about the parsed display orientation of an image with Exif
# data (jpeg or tiff).
#
# === Examples
#   require 'fastimage'
#
#   FastImage.size("https://switchstep.com/images/ios.gif")
#   => [196, 283]
#   FastImage.type("http://switchstep.com/images/ss_logo.png")
#   => :png
#   FastImage.type("/some/local/file.gif")
#   => :gif
#   File.open("/some/local/file.gif", "r") {|io| FastImage.type(io)}
#   => :gif
#   FastImage.new("http://switchstep.com/images/ss_logo.png").content_length
#   => 4679
#   FastImage.new("http://switchstep.com/images/ExifOrientation3.jpg").orientation
#   => 3
#
# === References
# * http://www.anttikupila.com/flash/getting-jpg-dimensions-with-as3-without-loading-the-entire-file/
# * http://pennysmalls.wordpress.com/2008/08/19/find-jpeg-dimensions-fast-in-pure-ruby-no-ima/
# * https://rubygems.org/gems/imagesize
# * https://github.com/remvee/exifr
#

require 'net/https'
require 'delegate'
require 'pathname'
require 'zlib'
require 'base64'
require 'uri'
require 'stringio'
require_relative 'fastimage/version'

# see http://stackoverflow.com/questions/5208851/i/41048816#41048816
if RUBY_VERSION < "2.2"
  module URI
    DEFAULT_PARSER = Parser.new(:HOSTNAME => "(?:(?:[a-zA-Z\\d](?:[-\\_a-zA-Z\\d]*[a-zA-Z\\d])?)\\.)*(?:[a-zA-Z](?:[-\\_a-zA-Z\\d]*[a-zA-Z\\d])?)\\.?")
  end
end

class FastImage
  attr_reader :size, :type, :content_length, :orientation, :animated

  attr_reader :bytes_read

  class FastImageException < StandardError # :nodoc:
  end
  class UnknownImageType < FastImageException # :nodoc:
  end
  class ImageFetchFailure < FastImageException # :nodoc:
  end
  class SizeNotFound < FastImageException # :nodoc:
  end
  class CannotParseImage < FastImageException # :nodoc:
  end
  class BadImageURI < FastImageException # :nodoc:
  end

  DefaultTimeout = 2 unless const_defined?(:DefaultTimeout)

  LocalFileChunkSize = 256 unless const_defined?(:LocalFileChunkSize)

  SUPPORTED_IMAGE_TYPES = [:bmp, :gif, :jpeg, :png, :tiff, :psd, :heic, :heif, :webp, :svg, :ico, :cur].freeze

  # Returns an array containing the width and height of the image.
  # It will return nil if the image could not be fetched, or if the image type was not recognised.
  #
  # By default there is a timeout of 2 seconds for opening and reading from a remote server.
  # This can be changed by passing a :timeout => number_of_seconds in the options.
  #
  # If you wish FastImage to raise if it cannot size the image for any reason, then pass
  # :raise_on_failure => true in the options.
  #
  # FastImage knows about GIF, JPEG, BMP, TIFF, ICO, CUR, PNG, PSD, SVG and WEBP files.
  #
  # === Example
  #
  #   require 'fastimage'
  #
  #   FastImage.size("https://switchstep.com/images/ios.gif")
  #   => [196, 283]
  #   FastImage.size("http://switchstep.com/images/ss_logo.png")
  #   => [300, 300]
  #   FastImage.size("https://upload.wikimedia.org/wikipedia/commons/0/09/Jpeg_thumb_artifacts_test.jpg")
  #   => [1280, 800]
  #   FastImage.size("https://eeweb.engineering.nyu.edu/~yao/EL5123/image/lena_gray.bmp")
  #   => [512, 512]
  #   FastImage.size("test/fixtures/test.jpg")
  #   => [882, 470]
  #   FastImage.size("http://switchstep.com/does_not_exist")
  #   => nil
  #   FastImage.size("http://switchstep.com/does_not_exist", :raise_on_failure=>true)
  #   => raises FastImage::ImageFetchFailure
  #   FastImage.size("http://switchstep.com/images/favicon.ico", :raise_on_failure=>true)
  #   => [16, 16]
  #   FastImage.size("http://switchstep.com/foo.ics", :raise_on_failure=>true)
  #   => raises FastImage::UnknownImageType
  #   FastImage.size("http://switchstep.com/images/favicon.ico", :raise_on_failure=>true, :timeout=>0.01)
  #   => raises FastImage::ImageFetchFailure
  #   FastImage.size("http://switchstep.com/images/faulty.jpg", :raise_on_failure=>true)
  #   => raises FastImage::SizeNotFound
  #
  # === Supported options
  # [:timeout]
  #   Overrides the default timeout of 2 seconds.  Applies both to reading from and opening the http connection.
  # [:raise_on_failure]
  #   If set to true causes an exception to be raised if the image size cannot be found for any reason.
  #
  def self.size(uri, options={})
    new(uri, options).size
  end

  # Returns an symbol indicating the image type fetched from a uri.
  # It will return nil if the image could not be fetched, or if the image type was not recognised.
  #
  # By default there is a timeout of 2 seconds for opening and reading from a remote server.
  # This can be changed by passing a :timeout => number_of_seconds in the options.
  #
  # If you wish FastImage to raise if it cannot find the type of the image for any reason, then pass
  # :raise_on_failure => true in the options.
  #
  # === Example
  #
  #   require 'fastimage'
  #
  #   FastImage.type("https://switchstep.com/images/ios.gif")
  #   => :gif
  #   FastImage.type("http://switchstep.com/images/ss_logo.png")
  #   => :png
  #   FastImage.type("https://upload.wikimedia.org/wikipedia/commons/0/09/Jpeg_thumb_artifacts_test.jpg")
  #   => :jpeg
  #   FastImage.type("https://eeweb.engineering.nyu.edu/~yao/EL5123/image/lena_gray.bmp")
  #   => :bmp
  #   FastImage.type("test/fixtures/test.jpg")
  #   => :jpeg
  #   FastImage.type("http://switchstep.com/does_not_exist")
  #   => nil
  #   File.open("/some/local/file.gif", "r") {|io| FastImage.type(io)}
  #   => :gif
  #   FastImage.type("test/fixtures/test.tiff")
  #   => :tiff
  #   FastImage.type("test/fixtures/test.psd")
  #   => :psd
  #
  # === Supported options
  # [:timeout]
  #   Overrides the default timeout of 2 seconds.  Applies both to reading from and opening the http connection.
  # [:raise_on_failure]
  #   If set to true causes an exception to be raised if the image type cannot be found for any reason.
  #
  def self.type(uri, options={})
    new(uri, options.merge(:type_only=>true)).type
  end

  # Returns a boolean value indicating the image is animated.
  # It will return nil if the image could not be fetched, or if the image type was not recognised.
  #
  # By default there is a timeout of 2 seconds for opening and reading from a remote server.
  # This can be changed by passing a :timeout => number_of_seconds in the options.
  #
  # If you wish FastImage to raise if it cannot find the type of the image for any reason, then pass
  # :raise_on_failure => true in the options.
  #
  # === Example
  #
  #   require 'fastimage'
  #
  #   FastImage.animated?("test/fixtures/test.gif")
  #   => false
  #   FastImage.animated?("test/fixtures/animated.gif")
  #   => true
  #
  # === Supported options
  # [:timeout]
  #   Overrides the default timeout of 2 seconds.  Applies both to reading from and opening the http connection.
  # [:raise_on_failure]
  #   If set to true causes an exception to be raised if the image type cannot be found for any reason.
  #
  def self.animated?(uri, options={})
    new(uri, options.merge(:animated_only=>true)).animated
  end

  def initialize(uri, options={})
    @uri = uri
    @options = {
      :type_only        => false,
      :timeout          => DefaultTimeout,
      :raise_on_failure => false,
      :proxy            => nil,
      :http_header      => {}
    }.merge(options)

    @property = if @options[:animated_only]
      :animated
    elsif @options[:type_only]
      :type
    else
      :size
    end

    raise BadImageURI if uri.nil?

    @type, @state = nil

    if uri.respond_to?(:read)
      fetch_using_read(uri)
    elsif uri.start_with?('data:')
      fetch_using_base64(uri)
    else
      begin
        @parsed_uri = URI.parse(uri)
      rescue URI::InvalidURIError
        fetch_using_file_open
      else
        if @parsed_uri.scheme == "http" || @parsed_uri.scheme == "https"
          fetch_using_http
        else
          fetch_using_file_open
        end
      end
    end

    raise SizeNotFound if @options[:raise_on_failure] && @property == :size && !@size

  rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ECONNRESET,
    Errno::ENETUNREACH, ImageFetchFailure, Net::HTTPBadResponse, EOFError, Errno::ENOENT,
    OpenSSL::SSL::SSLError
    raise ImageFetchFailure if @options[:raise_on_failure]
  rescue UnknownImageType, BadImageURI
    raise if @options[:raise_on_failure]
  rescue CannotParseImage
    if @options[:raise_on_failure]
      if @property == :size
        raise SizeNotFound
      else
        raise ImageFetchFailure
      end
    end

  ensure
    uri.rewind if uri.respond_to?(:rewind)

  end

  private

  def fetch_using_http
    @redirect_count = 0

    fetch_using_http_from_parsed_uri
  end

  # Some invalid locations need escaping
  def escaped_location(location)
    begin
      URI(location)
    rescue URI::InvalidURIError
      ::URI::DEFAULT_PARSER.escape(location)
    else
      location
    end
  end

  def fetch_using_http_from_parsed_uri
    http_header = {'Accept-Encoding' => 'identity'}.merge(@options[:http_header])

    setup_http
    @http.request_get(@parsed_uri.request_uri, http_header) do |res|
      if res.is_a?(Net::HTTPRedirection) && @redirect_count < 4
        @redirect_count += 1
        begin
          location = res['Location']
          raise ImageFetchFailure if location.nil? || location.empty?

          @parsed_uri = URI.join(@parsed_uri, escaped_location(location))
        rescue URI::InvalidURIError
        else
          fetch_using_http_from_parsed_uri
          break
        end
      end

      raise ImageFetchFailure unless res.is_a?(Net::HTTPSuccess)

      @content_length = res.content_length

      read_fiber = Fiber.new do
        res.read_body do |str|
          Fiber.yield str
        end
        nil
      end

      case res['content-encoding']
      when 'deflate', 'gzip', 'x-gzip'
        begin
          gzip = Zlib::GzipReader.new(FiberStream.new(read_fiber))
        rescue FiberError, Zlib::GzipFile::Error
          raise CannotParseImage
        end

        read_fiber = Fiber.new do
          while data = gzip.readline
            Fiber.yield data
          end
          nil
        end
      end

      parse_packets FiberStream.new(read_fiber)

      break  # needed to actively quit out of the fetch
    end
  end

  def protocol_relative_url?(url)
    url.start_with?("//")
  end

  def proxy_uri
    begin
      if @options[:proxy]
        proxy = URI.parse(@options[:proxy])
      else
        proxy = ENV['http_proxy'] && ENV['http_proxy'] != "" ? URI.parse(ENV['http_proxy']) : nil
      end
    rescue URI::InvalidURIError
      proxy = nil
    end
    proxy
  end

  def setup_http
    proxy = proxy_uri

    if proxy
      @http = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password).new(@parsed_uri.host, @parsed_uri.port)
    else
      @http = Net::HTTP.new(@parsed_uri.host, @parsed_uri.port)
    end
    @http.use_ssl = (@parsed_uri.scheme == "https")
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @http.open_timeout = @options[:timeout]
    @http.read_timeout = @options[:timeout]
  end

  def fetch_using_read(readable)
    readable.rewind if readable.respond_to?(:rewind)
    # Pathnames respond to read, but always return the first
    # chunk of the file unlike an IO (even though the
    # docuementation for it refers to IO). Need to supply
    # an offset in this case.
    if readable.is_a?(Pathname)
      read_fiber = Fiber.new do
        offset = 0
        while str = readable.read(LocalFileChunkSize, offset)
          Fiber.yield str
          offset += LocalFileChunkSize
        end
        nil
      end
    else
      read_fiber = Fiber.new do
        while str = readable.read(LocalFileChunkSize)
          Fiber.yield str
        end
        nil
      end
    end

    parse_packets FiberStream.new(read_fiber)
  end

  def fetch_using_file_open
    @content_length = File.size?(@uri)
    File.open(@uri) do |s|
      fetch_using_read(s)
    end
  end

  def parse_packets(stream)
    @stream = stream

    begin
      result = send("parse_#{@property}")
      if result != nil
        # extract exif orientation if it was found
        if @property == :size && result.size == 3
          @orientation = result.pop
        else
          @orientation = 1
        end

        instance_variable_set("@#{@property}", result)
      else
        raise CannotParseImage
      end
    rescue FiberError
      raise CannotParseImage
    end
  end

  def parse_size
    @type = parse_type unless @type
    send("parse_size_for_#{@type}")
  end

  def parse_animated
    @type = parse_type unless @type
    %i(gif png webp avif).include?(@type) ? send("parse_animated_for_#{@type}") : nil
  end

  def fetch_using_base64(uri)
    decoded = begin
      Base64.decode64(uri.split(',')[1])
    rescue
      raise CannotParseImage
    end
    @content_length = decoded.size
    fetch_using_read StringIO.new(decoded)
  end

  module StreamUtil # :nodoc:
    def read_byte
      read(1)[0].ord
    end

    def read_int
      read(2).unpack('n')[0]
    end

    def read_string_int
      value = []
      while read(1) =~ /(\d)/
        value << $1
      end
      value.join.to_i
    end
  end

  class FiberStream # :nodoc:
    include StreamUtil
    attr_reader :pos

    # read_fiber should return nil if it no longer has anything to return when resumed
    # so the result of the whole Fiber block should be set to be nil in case yield is no
    # longer called
    def initialize(read_fiber)
      @read_fiber = read_fiber
      @pos = 0
      @strpos = 0
      @str = ''
    end

    # Peeking beyond the end of the input will raise
    def peek(n)
      while @strpos + n > @str.size
        unused_str = @str[@strpos..-1]

        new_string = @read_fiber.resume
        raise CannotParseImage if !new_string
        # we are dealing with bytes here, so force the encoding
        new_string.force_encoding("ASCII-8BIT") if new_string.respond_to? :force_encoding

        @str = unused_str + new_string
        @strpos = 0
      end

      @str[@strpos, n]
    end

    def read(n)
      result = peek(n)
      @strpos += n
      @pos += n
      result
    end

    def skip(n)
      discarded = 0
      fetched = @str[@strpos..-1].size
      while n > fetched
        discarded += @str[@strpos..-1].size
        new_string = @read_fiber.resume
        raise CannotParseImage if !new_string

        new_string.force_encoding("ASCII-8BIT") if new_string.respond_to? :force_encoding

        fetched += new_string.size
        @str = new_string
        @strpos = 0
      end
      @strpos = @strpos + n - discarded
      @pos += n
    end
  end

  class IOStream < SimpleDelegator # :nodoc:
    include StreamUtil
  end

  def parse_type
    parsed_type = case @stream.peek(2)
    when "BM"
      :bmp
    when "GI"
      :gif
    when 0xff.chr + 0xd8.chr
      :jpeg
    when 0x89.chr + "P"
      :png
    when "II", "MM"
      case @stream.peek(11)[8..10]
      when "APC", "CR\002"
        nil  # do not recognise CRW or CR2 as tiff
      else
        :tiff
      end
    when '8B'
      :psd
    when "\0\0"
      case @stream.peek(3).bytes.to_a.last
      when 0
        # http://www.ftyps.com/what.html
        case @stream.peek(12)[4..-1]
        when "ftypavif"
          :avif
        when "ftypavis"
          :avif
        when "ftypheic"
          :heic
        when "ftypmif1"
          :heif
        end
      # ico has either a 1 (for ico format) or 2 (for cursor) at offset 3
      when 1 then :ico
      when 2 then :cur
      end
    when "RI"
      :webp if @stream.peek(12)[8..11] == "WEBP"
    when "<s"
      :svg if @stream.peek(4) == "<svg"
    when /\s\s|\s<|<[?!]/, 0xef.chr + 0xbb.chr
      # Peek 10 more chars each time, and if end of file is reached just raise
      # unknown. We assume the <svg tag cannot be within 10 chars of the end of
      # the file, and is within the first 1000 chars.
      begin
        :svg if (1..100).detect {|n| @stream.peek(10 * n).include?("<svg")}
      rescue FiberError, CannotParseImage
        nil
      end
    end

    parsed_type or raise UnknownImageType
  end

  def parse_size_for_ico
    icons = @stream.read(6)[4..5].unpack('v').first
    sizes = icons.times.map { @stream.read(16).unpack('C2').map { |x| x == 0 ? 256 : x } }.sort_by { |w,h| w * h }
    sizes.last
  end
  alias_method :parse_size_for_cur, :parse_size_for_ico

  # HEIC/AVIF are a special case of the general ISO_BMFF format, in which all data is encapsulated in typed boxes,
  # with a mandatory ftyp box that is used to indicate particular file types. Is composed of nested "boxes". Each
  # box has a header composed of
  # - Size (32 bit integer)
  # - Box type (4 chars)
  # - Extended size: only if size === 1, the type field is followed by 64 bit integer of extended size
  # - Payload: Type-dependent
  class IsoBmff # :nodoc:
    def initialize(stream)
      @stream = stream
    end

    def width_and_height
      @rotation = 0
      @max_size = nil
      @primary_box = nil
      @ipma_boxes = []
      @ispe_boxes = []
      @final_size = nil

      catch :finish do
        read_boxes!
      end

      if [90, 270].include?(@rotation)
        @final_size.reverse
      else
        @final_size
      end
    end

    private

    # Format specs: https://www.loc.gov/preservation/digital/formats/fdd/fdd000525.shtml

    # If you need to inspect a heic/heif file, use
    # https://gpac.github.io/mp4box.js/test/filereader.html
    def read_boxes!(max_read_bytes = nil)
      end_pos = max_read_bytes.nil? ? nil : @stream.pos + max_read_bytes
      index = 0

      loop do
        return if end_pos && @stream.pos >= end_pos

        box_type, box_size = read_box_header!

        case box_type
        when "meta"
          handle_meta_box(box_size)
        when "pitm"
          handle_pitm_box(box_size)
        when "ipma"
          handle_ipma_box(box_size)
        when "hdlr"
          handle_hdlr_box(box_size)
        when "iprp", "ipco"
          read_boxes!(box_size)
        when "irot"
          handle_irot_box
        when "ispe"
          handle_ispe_box(box_size, index)
        when "mdat"
          @stream.skip(box_size)
        else
          @stream.skip(box_size)
        end

        index += 1
      end
    end

    def handle_irot_box
      @rotation = (read_uint8! & 0x3) * 90
    end

    def handle_ispe_box(box_size, index)
      throw :finish if box_size < 12

      data = @stream.read(box_size)
      width, height = data[4...12].unpack("N2")
      @ispe_boxes << { index: index, size: [width, height] }
    end

    def handle_hdlr_box(box_size)
      throw :finish if box_size < 12

      data = @stream.read(box_size)
      throw :finish if data[8...12] != "pict"
    end

    def handle_ipma_box(box_size)
      @stream.read(3)
      flags3 = read_uint8!
      entries_count = read_uint32!

      entries_count.times do
        id = read_uint16!
        essen_count = read_uint8!

        essen_count.times do
          property_index = read_uint8! & 0x7F

          if flags3 & 1 == 1
            property_index = (property_index << 7) + read_uint8!
          end

          @ipma_boxes << { id: id, property_index: property_index - 1 }
        end
      end
    end

    def handle_pitm_box(box_size)
      data = @stream.read(box_size)
      @primary_box = data[4...6].unpack("S>")[0]
    end

    def handle_meta_box(box_size)
      throw :finish if box_size < 4

      @stream.read(4)
      read_boxes!(box_size - 4)

      throw :finish if !@primary_box

      primary_indices = @ipma_boxes
                        .select { |box| box[:id] == @primary_box }
                        .map { |box| box[:property_index] }

      ispe_box = @ispe_boxes.find do |box|
        primary_indices.include?(box[:index])
      end

      if ispe_box
        @final_size = ispe_box[:size]
      end

      throw :finish
    end

    def read_box_header!
      size = read_uint32!
      type = @stream.read(4)
      size = read_uint64! - 8 if size == 1
      [type, size - 8]
    end

    def read_uint8!
      @stream.read(1).unpack("C")[0]
    end

    def read_uint16!
      @stream.read(2).unpack("S>")[0]
    end

    def read_uint32!
      @stream.read(4).unpack("N")[0]
    end

    def read_uint64!
      @stream.read(8).unpack("Q>")[0]
    end
  end

  def parse_size_for_avif
    bmff = IsoBmff.new(@stream)
    bmff.width_and_height
  end

  def parse_size_for_heic
    bmff = IsoBmff.new(@stream)
    bmff.width_and_height
  end

  def parse_size_for_heif
    bmff = IsoBmff.new(@stream)
    bmff.width_and_height
  end

  class Gif # :nodoc:
    def initialize(stream)
      @stream = stream
    end

    def width_and_height
      @stream.read(11)[6..10].unpack('SS')
    end

    # Checks if a delay between frames exists and if it does, then the GIFs is
    # animated
    def animated?
      frames = 0

      # "GIF" + version (3) + width (2) + height (2)
      @stream.skip(10)

      # fields (1) + bg color (1) + pixel ratio (1)
      fields = @stream.read(3).unpack("CCC")[0]
      if fields & 0x80 != 0 # Global Color Table
        # 2 * (depth + 1) colors, each occupying 3 bytes (RGB)
        @stream.skip(3 * 2 ** ((fields & 0x7) + 1))
      end

      loop do
        block_type = @stream.read(1).unpack("C")[0]

        if block_type == 0x21 # Graphic Control Extension
          # extension type (1) + size (1)
          size = @stream.read(2).unpack("CC")[1]
          @stream.skip(size)
          skip_sub_blocks
        elsif block_type == 0x2C # Image Descriptor
          frames += 1
          return true if frames > 1

          # left position (2) + top position (2) + width (2) + height (2) + fields (1)
          fields = @stream.read(9).unpack("SSSSC")[4]
          if fields & 0x80 != 0 # Local Color Table
            # 2 * (depth + 1) colors, each occupying 3 bytes (RGB)
            @stream.skip(3 * 2 ** ((fields & 0x7) + 1))
          end

          @stream.skip(1) # LZW min code size (1)
          skip_sub_blocks
        else
          break # unrecognized block
        end
      end

      false
    end

    private

    def skip_sub_blocks
      loop do
        size = @stream.read(1).unpack("C")[0]
        if size == 0
          break
        else
          @stream.skip(size)
        end
      end
    end
  end

  def parse_size_for_gif
    gif = Gif.new(@stream)
    gif.width_and_height
  end

  def parse_size_for_png
    @stream.read(25)[16..24].unpack('NN')
  end

  def parse_size_for_jpeg
    exif = nil
    loop do
      @state = case @state
      when nil
        @stream.skip(2)
        :started
      when :started
        @stream.read_byte == 0xFF ? :sof : :started
      when :sof
        case @stream.read_byte
        when 0xe1 # APP1
          skip_chars = @stream.read_int - 2
          data = @stream.read(skip_chars)
          io = StringIO.new(data)
          if io.read(4) == "Exif"
            io.read(2)
            new_exif = Exif.new(IOStream.new(io)) rescue nil
            exif ||= new_exif # only use the first APP1 segment
          end
          :started
        when 0xe0..0xef
          :skipframe
        when 0xC0..0xC3, 0xC5..0xC7, 0xC9..0xCB, 0xCD..0xCF
          :readsize
        when 0xFF
          :sof
        else
          :skipframe
        end
      when :skipframe
        skip_chars = @stream.read_int - 2
        @stream.skip(skip_chars)
        :started
      when :readsize
        @stream.skip(3)
        height = @stream.read_int
        width = @stream.read_int
        width, height = height, width if exif && exif.rotated?
        return [width, height, exif ? exif.orientation : 1]
      end
    end
  end

  def parse_size_for_bmp
    d = @stream.read(32)[14..28]
    header = d.unpack("C")[0]

    result = if header == 12
               d[4..8].unpack('SS')
             else
               d[4..-1].unpack('l<l<')
             end

    # ImageHeight is expressed in pixels. The absolute value is necessary because ImageHeight can be negative
    [result.first, result.last.abs]
  end

  def parse_size_for_webp
    vp8 = @stream.read(16)[12..15]
    _len = @stream.read(4).unpack("V")
    case vp8
    when "VP8 "
      parse_size_vp8
    when "VP8L"
      parse_size_vp8l
    when "VP8X"
      parse_size_vp8x
    else
      nil
    end
  end

  def parse_size_vp8
    w, h = @stream.read(10).unpack("@6vv")
    [w & 0x3fff, h & 0x3fff]
  end

  def parse_size_vp8l
    @stream.skip(1) # 0x2f
    b1, b2, b3, b4 = @stream.read(4).bytes.to_a
    [1 + (((b2 & 0x3f) << 8) | b1), 1 + (((b4 & 0xF) << 10) | (b3 << 2) | ((b2 & 0xC0) >> 6))]
  end

  def parse_size_vp8x
    flags = @stream.read(4).unpack("C")[0]
    b1, b2, b3, b4, b5, b6 = @stream.read(6).unpack("CCCCCC")
    width, height = 1 + b1 + (b2 << 8) + (b3 << 16), 1 + b4 + (b5 << 8) + (b6 << 16)

    if flags & 8 > 0 # exif
      # parse exif for orientation
      # TODO: find or create test images for this
    end

    return [width, height]
  end

  class Exif # :nodoc:
    attr_reader :width, :height, :orientation

    def initialize(stream)
      @stream = stream
      @width, @height, @orientation = nil
      parse_exif
    end

    def rotated?
      @orientation >= 5
    end

    private

    def get_exif_byte_order
      byte_order = @stream.read(2)
      case byte_order
      when 'II'
        @short, @long = 'v', 'V'
      when 'MM'
        @short, @long = 'n', 'N'
      else
        raise CannotParseImage
      end
    end

    def parse_exif_ifd
      tag_count = @stream.read(2).unpack(@short)[0]
      tag_count.downto(1) do
        type = @stream.read(2).unpack(@short)[0]
        @stream.read(6)
        data = @stream.read(2).unpack(@short)[0]
        case type
        when 0x0100 # image width
          @width = data
        when 0x0101 # image height
          @height = data
        when 0x0112 # orientation
          @orientation = data
        end
        if @width && @height && @orientation
          return # no need to parse more
        end
        @stream.read(2)
      end
    end

    def parse_exif
      @start_byte = @stream.pos

      get_exif_byte_order

      @stream.read(2) # 42

      offset = @stream.read(4).unpack(@long)[0]
      if @stream.respond_to?(:skip)
        @stream.skip(offset - 8)
      else
        @stream.read(offset - 8)
      end

      parse_exif_ifd

      @orientation ||= 1
    end

  end

  def parse_size_for_tiff
    exif = Exif.new(@stream)
    if exif.rotated?
      [exif.height, exif.width, exif.orientation]
    else
      [exif.width, exif.height, exif.orientation]
    end
  end

  def parse_size_for_psd
    @stream.read(26).unpack("x14NN").reverse
  end

  class Svg # :nodoc:
    def initialize(stream)
      @stream = stream
      @width, @height, @ratio, @viewbox_width, @viewbox_height = nil
      parse_svg
    end

    def width_and_height
      if @width && @height
        [@width, @height]
      elsif @width && @ratio
        [@width, @width / @ratio]
      elsif @height && @ratio
        [@height * @ratio, @height]
      elsif @viewbox_width && @viewbox_height
        [@viewbox_width, @viewbox_height]
      else
        nil
      end
    end

    private

    def parse_svg
      attr_name = []
      state = nil

      while (char = @stream.read(1)) && state != :stop do
        case char
        when "="
          if attr_name.join =~ /width/i
            @stream.read(1)
            @width = @stream.read_string_int
            return if @height
          elsif attr_name.join =~ /height/i
            @stream.read(1)
            @height = @stream.read_string_int
            return if @width
          elsif attr_name.join =~ /viewbox/i
            values = attr_value.split(/\s/)
            if values[2].to_f > 0 && values[3].to_f > 0
              @ratio = values[2].to_f / values[3].to_f
              @viewbox_width = values[2].to_i
              @viewbox_height = values[3].to_i
            end
          end
        when /\w/
          attr_name << char
        when "<"
          attr_name = [char]
        when ">"
          state = :stop if state == :started
        else
          state = :started if attr_name.join == "<svg"
          attr_name.clear
        end
      end
    end

    def attr_value
      @stream.read(1)

      value = []
      while @stream.read(1) =~ /([^"])/
        value << $1
      end
      value.join
    end
  end

  def parse_size_for_svg
    svg = Svg.new(@stream)
    svg.width_and_height
  end

  def parse_animated_for_gif
    gif = Gif.new(@stream)
    gif.animated?
  end

  def parse_animated_for_png
    # Signature (8) + IHDR chunk (4 + 4 + 13 + 4)
    @stream.read(33)

    loop do
      length = @stream.read(4).unpack("L>")[0]
      type = @stream.read(4)

      case type
      when "acTL"
        return true
      when "IDAT"
        return false
      end

      @stream.skip(length + 4)
    end
  end

  def parse_animated_for_webp
    vp8 = @stream.read(16)[12..15]
    _len = @stream.read(4).unpack("V")
    case vp8
    when "VP8 "
      false
    when "VP8L"
      false
    when "VP8X"
      flags = @stream.read(4).unpack("C")[0]
      flags & 2 > 0
    else
      nil
    end
  end

  def parse_animated_for_avif
    @stream.peek(12)[4..-1] == "ftypavis"
  end
end
