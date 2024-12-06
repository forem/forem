# Copyright (c) 2007-2017 - R.W. van 't Veer

require 'exifr'
require 'rational'
require 'enumerator'

module EXIFR
  # = TIFF decoder
  #
  # == Date properties
  # The properties <tt>:date_time</tt>, <tt>:date_time_original</tt>,
  # <tt>:date_time_digitized</tt> coerced into Time objects.
  #
  # == Orientation
  # The property <tt>:orientation</tt> describes the subject rotated and/or
  # mirrored in relation to the camera.  It is translated to one of the following
  # instances:
  # * TopLeftOrientation
  # * TopRightOrientation
  # * BottomRightOrientation
  # * BottomLeftOrientation
  # * LeftTopOrientation
  # * RightTopOrientation
  # * RightBottomOrientation
  # * LeftBottomOrientation
  #
  # These instances of Orientation have two methods:
  # * <tt>to_i</tt>; return the original integer
  # * <tt>transform_rmagick(image)</tt>; transforms the given RMagick::Image
  #   to a viewable version
  #
  # == Examples
  #   EXIFR::TIFF.new('DSC_0218.TIF').width           # => 3008
  #   EXIFR::TIFF.new('DSC_0218.TIF')[1].width        # => 160
  #   EXIFR::TIFF.new('DSC_0218.TIF').model           # => "NIKON D1X"
  #   EXIFR::TIFF.new('DSC_0218.TIF').date_time       # => Tue May 23 19:15:32 +0200 2006
  #   EXIFR::TIFF.new('DSC_0218.TIF').exposure_time   # => Rational(1, 100)
  #   EXIFR::TIFF.new('DSC_0218.TIF').orientation     # => EXIFR::TIFF::Orientation
  class TIFF
    include Enumerable

    # JPEG thumbnails
    attr_reader :jpeg_thumbnails

    TAG_MAPPING = {} # :nodoc:
    TAG_MAPPING.merge!({
      :image => {
        0x00FE => :new_subfile_type,
        0x00FF => :subfile_type,
        0x0100 => :image_width,
        0x0101 => :image_length,
        0x0102 => :bits_per_sample,
        0x0103 => :compression,
        0x0106 => :photometric_interpretation,
        0x0107 => :threshholding,
        0x0108 => :cell_width,
        0x0109 => :cell_length,
        0x010a => :fill_order,
        0x010d => :document_name,
        0x010e => :image_description,
        0x010f => :make,
        0x0110 => :model,
        0x0111 => :strip_offsets,
        0x0112 => :orientation,
        0x0115 => :samples_per_pixel,
        0x0116 => :rows_per_strip,
        0x0117 => :strip_byte_counts,
        0x0118 => :min_sample_value,
        0x0119 => :max_sample_value,
        0x011a => :x_resolution,
        0x011b => :y_resolution,
        0x011c => :planar_configuration,
        0x011d => :page_name,
        0x011e => :x_position,
        0x011f => :y_position,
        0x0120 => :free_offsets,
        0x0121 => :free_byte_counts,
        0x0122 => :gray_response_unit,
        0x0123 => :gray_response_curve,
        0x0124 => :t4_options,
        0x0125 => :t6_options,
        0x0128 => :resolution_unit,
        0x012d => :transfer_function,
        0x0131 => :software,
        0x0132 => :date_time,
        0x013b => :artist,
        0x013c => :host_computer,
        0x013a => :predictor,
        0x013e => :white_point,
        0x013f => :primary_chromaticities,
        0x0140 => :color_map,
        0x0141 => :halftone_hints,
        0x0142 => :tile_width,
        0x0143 => :tile_length,
        0x0144 => :tile_offsets,
        0x0145 => :tile_byte_counts,
        0x0146 => :bad_fax_lines,
        0x0147 => :clean_fax_data,
        0x0148 => :consecutive_bad_fax_lines,
        0x014a => :sub_ifds,
        0x014c => :ink_set,
        0x014d => :ink_names,
        0x014e => :number_of_inks,
        0x0150 => :dot_range,
        0x0151 => :target_printer,
        0x0152 => :extra_samples,
        0x0156 => :transfer_range,
        0x0157 => :clip_path,
        0x0158 => :x_clip_path_units,
        0x0159 => :y_clip_path_units,
        0x015a => :indexed,
        0x015b => :jpeg_tables,
        0x015f => :opi_proxy,
        0x0190 => :global_parameters_ifd,
        0x0191 => :profile_type,
        0x0192 => :fax_profile,
        0x0193 => :coding_methods,
        0x0194 => :version_year,
        0x0195 => :mode_number,
        0x01B1 => :decode,
        0x01B2 => :default_image_color,
        0x0200 => :jpegproc,
        0x0201 => :jpeg_interchange_format,
        0x0202 => :jpeg_interchange_format_length,
        0x0203 => :jpeg_restart_interval,
        0x0205 => :jpeg_lossless_predictors,
        0x0206 => :jpeg_point_transforms,
        0x0207 => :jpeg_q_tables,
        0x0208 => :jpeg_dc_tables,
        0x0209 => :jpeg_ac_tables,
        0x0211 => :ycb_cr_coefficients,
        0x0212 => :ycb_cr_sub_sampling,
        0x0213 => :ycb_cr_positioning,
        0x0214 => :reference_black_white,
        0x022F => :strip_row_counts,
        0x02BC => :xmp,
        0x800D => :image_id,
        0x87AC => :image_layer,
        0x8298 => :copyright,
        0x83bb => :iptc,

        0x8769 => :exif,
        0x8825 => :gps,
      },

      :exif => {
        0x829a => :exposure_time,
        0x829d => :f_number,
        0x8822 => :exposure_program,
        0x8824 => :spectral_sensitivity,
        0x8827 => :iso_speed_ratings,
        0x8828 => :oecf,
        0x9000 => :exif_version,
        0x9003 => :date_time_original,
        0x9004 => :date_time_digitized,
        0x9101 => :components_configuration,
        0x9102 => :compressed_bits_per_pixel,
        0x9201 => :shutter_speed_value,
        0x9202 => :aperture_value,
        0x9203 => :brightness_value,
        0x9204 => :exposure_bias_value,
        0x9205 => :max_aperture_value,
        0x9206 => :subject_distance,
        0x9207 => :metering_mode,
        0x9208 => :light_source,
        0x9209 => :flash,
        0x920a => :focal_length,
        0x9214 => :subject_area,
        0x927c => :maker_note,
        0x9286 => :user_comment,
        0x9290 => :subsec_time,
        0x9291 => :subsec_time_original,
        0x9292 => :subsec_time_digitized,
        0xa000 => :flashpix_version,
        0xa001 => :color_space,
        0xa002 => :pixel_x_dimension,
        0xa003 => :pixel_y_dimension,
        0xa004 => :related_sound_file,
        0xa20b => :flash_energy,
        0xa20c => :spatial_frequency_response,
        0xa20e => :focal_plane_x_resolution,
        0xa20f => :focal_plane_y_resolution,
        0xa210 => :focal_plane_resolution_unit,
        0xa214 => :subject_location,
        0xa215 => :exposure_index,
        0xa217 => :sensing_method,
        0xa300 => :file_source,
        0xa301 => :scene_type,
        0xa302 => :cfa_pattern,
        0xa401 => :custom_rendered,
        0xa402 => :exposure_mode,
        0xa403 => :white_balance,
        0xa404 => :digital_zoom_ratio,
        0xa405 => :focal_length_in_35mm_film,
        0xa406 => :scene_capture_type,
        0xa407 => :gain_control,
        0xa408 => :contrast,
        0xa409 => :saturation,
        0xa40a => :sharpness,
        0xa40b => :device_setting_description,
        0xa40c => :subject_distance_range,
        0xa420 => :image_unique_id,
        0xa433 => :lens_make,
        0xa434 => :lens_model,
        0xa435 => :lens_serial_number
      },

      :gps => {
        0x0000 => :gps_version_id,
        0x0001 => :gps_latitude_ref,
        0x0002 => :gps_latitude,
        0x0003 => :gps_longitude_ref,
        0x0004 => :gps_longitude,
        0x0005 => :gps_altitude_ref,
        0x0006 => :gps_altitude  ,
        0x0007 => :gps_time_stamp,
        0x0008 => :gps_satellites,
        0x0009 => :gps_status,
        0x000a => :gps_measure_mode,
        0x000b => :gps_dop,
        0x000c => :gps_speed_ref,
        0x000d => :gps_speed,
        0x000e => :gps_track_ref,
        0x000f => :gps_track,
        0x0010 => :gps_img_direction_ref,
        0x0011 => :gps_img_direction,
        0x0012 => :gps_map_datum,
        0x0013 => :gps_dest_latitude_ref,
        0x0014 => :gps_dest_latitude,
        0x0015 => :gps_dest_longitude_ref,
        0x0016 => :gps_dest_longitude,
        0x0017 => :gps_dest_bearing_ref,
        0x0018 => :gps_dest_bearing,
        0x0019 => :gps_dest_distance_ref,
        0x001a => :gps_dest_distance,
        0x001b => :gps_processing_method,
        0x001c => :gps_area_information,
        0x001d => :gps_date_stamp,
        0x001e => :gps_differential,
        0x001f => :gps_h_positioning_error
      },
    })
    IFD_TAGS = [:image, :exif, :gps] # :nodoc:

    class << self
      # Callable to create a +Time+ object.  Defaults to <tt>proc{|*a|Time.local(*a)}</tt>.
      attr_accessor :mktime_proc
    end
    self.mktime_proc = proc { |*args| Time.local(*args) }

    time_proc = proc do |value|
      value.map do |v|
        if v =~ /^(\d{4}):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)(?:\.(\d{3}))?$/
          begin
            mktime_proc.call($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, $7.to_i * 1000)
          rescue => ex
            EXIFR.logger.warn("Bad date/time value #{v.inspect}: #{ex}")
            nil
          end
        else
          v
        end
      end
    end

    # The orientation of the image with respect to the rows and columns.
    class Orientation
      def initialize(value, type) # :nodoc:
        @value, @type = value, type
      end

      # Field value.
      def to_i
        @value
      end

      # Symbolic value.
      def to_sym
        @type
      end

      # Debugging output.
      def inspect
        "\#<EXIFR::TIFF::Orientation:#{@type}(#{@value})>"
      end

      # Rotate and/or flip for proper viewing.
      def transform_rmagick(img)
        case @type
        when :TopRight    ; img.flop
        when :BottomRight ; img.rotate(180)
        when :BottomLeft  ; img.flip
        when :LeftTop     ; img.rotate(90).flop
        when :RightTop    ; img.rotate(90)
        when :RightBottom ; img.rotate(270).flop
        when :LeftBottom  ; img.rotate(270)
        else
          img
        end
      end

      def ==(other) # :nodoc:
        Orientation === other && to_i == other.to_i
      end
    end

    ORIENTATIONS = [] # :nodoc:
    [
      nil,
      :TopLeft,
      :TopRight,
      :BottomRight,
      :BottomLeft,
      :LeftTop,
      :RightTop,
      :RightBottom,
      :LeftBottom,
    ].each_with_index do |type,index|
      next unless type
      const_set("#{type}Orientation", ORIENTATIONS[index] = Orientation.new(index, type))
    end

    degrees_proc = proc do |v|
      begin
        Degrees.new(v)
      rescue => ex
        EXIFR.logger.warn("malformed GPS degrees: #{ex}")
        nil
      end
    end

    class Degrees < Array
      def initialize(arr)
        unless arr.length == 3 && arr.all?{|v| Rational === v}
          raise "expected [degrees, minutes, seconds]; got #{arr.inspect}"
        end
        super
      end

      def to_f
        reduce { |m,v| m * 60 + v}.to_f / 3600
      end
    end

    def self.rational(n, d)
      if d == 0
        n.to_f / d.to_f
      elsif Rational.respond_to?(:reduce)
        Rational.reduce(n, d)
      else
        n.quo(d)
      end
    end

    def self.round(f, n)
      q = (10 ** n)
      (f * q).round.to_f / q
    end

    ADAPTERS = Hash.new { proc { |v| v } } # :nodoc:
    ADAPTERS.merge!({
                      :date_time_original => time_proc,
                      :date_time_digitized => time_proc,
                      :date_time => time_proc,
                      :orientation => proc { |x| x.map{|y| ORIENTATIONS[y]} },
                      :gps_latitude => degrees_proc,
                      :gps_longitude => degrees_proc,
                      :gps_dest_latitude => degrees_proc,
                      :gps_dest_longitude => degrees_proc,
                      :shutter_speed_value => proc { |x| x.map { |y| y.abs < 100 ? rational(1, (2 ** y).to_i) : nil } },
                      :aperture_value => proc { |x| x.map { |y| round(1.4142 ** y, 1) } }
                    })

    # Names for all recognized TIFF fields.
    TAGS = [TAG_MAPPING.keys, TAG_MAPPING.values.map{|v|v.values}].flatten.uniq - IFD_TAGS

    # +file+ is a filename or an +IO+ object.  Hint: use +StringIO+ when working with slurped data like blobs.
    def initialize(file, load_thumbnails: true)
      Data.open(file) do |data|
        @ifds = [IFD.new(data)]
        while ifd = @ifds.last.next
          break if @ifds.find{|i| i.offset == ifd.offset}
          @ifds << ifd
        end

        if load_thumbnails
          @jpeg_thumbnails = @ifds.map do |v|
            if v.jpeg_interchange_format && v.jpeg_interchange_format_length
              start, length = v.jpeg_interchange_format, v.jpeg_interchange_format_length
              if Integer === start && Integer === length
                data[start..(start + length)]
              else
                EXIFR.logger.warn("Non numeric JpegInterchangeFormat data")
                nil
              end
            end
          end.compact
        else
          @jpeg_thumbnails = []
        end
      end
    end

    # Number of images.
    def size
      @ifds.size
    end

    # Yield for each image.
    def each
      @ifds.each { |ifd| yield ifd }
    end

    # Get +index+ image.
    def [](index)
      index.is_a?(Symbol) ? to_hash[index] : @ifds[index]
    end

    # Dispatch to first image.
    def method_missing(method, *args)
      super unless args.empty?

      if @ifds.first.respond_to?(method)
        @ifds.first.send(method)
      elsif TAGS.include?(method)
        @ifds.first.to_hash[method]
      else
        super
      end
    end

    def respond_to?(method, include_all = false) # :nodoc:
      super ||
        (defined?(@ifds) && @ifds && @ifds.first && @ifds.first.respond_to?(method, include_all)) ||
        TAGS.include?(method)
    end

    def methods(regular=true) # :nodoc:
      if regular
        (super + TAGS + IFD.instance_methods(false)).uniq
      else
        super
      end
    end

    def encode_with(coder)
      coder["ifds"] = @ifds
    end

    def to_yaml_properties
      ['@ifds']
    end

    class << self
      alias instance_methods_without_tiff_extras instance_methods
      def instance_methods(include_super = true) # :nodoc:
        (instance_methods_without_tiff_extras(include_super) + TAGS + IFD.instance_methods(false)).uniq
      end
    end

    # Convenience method to access image width.
    def width; @ifds.first.width; end

    # Convenience method to access image height.
    def height; @ifds.first.height; end

    # Get a hash presentation of the (first) image.
    def to_hash; @ifds.first.to_hash; end

    GPS = Struct.new(:latitude, :longitude, :altitude, :image_direction)

    # Get GPS location, altitude and image direction return nil when not available.
    def gps
      return nil unless gps_latitude && gps_longitude

      altitude = gps_altitude.is_a?(Array) ? gps_altitude.first : gps_altitude

      GPS.new(gps_latitude.to_f * (gps_latitude_ref == 'S' ? -1 : 1),
              gps_longitude.to_f * (gps_longitude_ref == 'W' ? -1 : 1),
              altitude && (altitude.to_f * (gps_altitude_ref == "\1" ? -1 : 1)),
              gps_img_direction && gps_img_direction.to_f)
    end

    def inspect # :nodoc:
      @ifds.inspect
    end

    class IFD # :nodoc:
      attr_reader :type, :raw_fields, :fields, :offset

      def initialize(data, offset = nil, type = :image)
        @data, @offset, @type, @raw_fields, @fields = data, offset, type, {}, {}

        pos = offset || @data.readlong(4)
        num = @data.readshort(pos)

        if pos && num
          pos += 2

          num.times do
            add_field(Field.new(@data, pos))
            pos += 12
          end

          @offset_next = @data.readlong(pos)
        end
      rescue => ex
        EXIFR.logger.warn("Badly formed IFD: #{ex}")
      end

      def method_missing(method, *args)
        super unless args.empty? && TAGS.include?(method)
        to_hash[method]
      end

      def width; image_width; end
      def height; image_length; end

      def to_hash
        @hash ||= @fields.map do |key,value|
          if value.nil?
            {}
          elsif IFD_TAGS.include?(key)
            value.to_hash
          else
            {key => value}
          end
        end.inject { |m,v| m.merge(v) } || {}
      end

      def inspect
        to_hash.inspect
      end

      def next?
        @offset_next && @offset_next > 0 && @offset_next < @data.size
      end

      def next
        IFD.new(@data, @offset_next) if next?
      end

      def encode_with(coder)
        coder["fields"] = @fields
      end

      def to_yaml_properties
        ['@fields']
      end

    private
      def add_field(field)
        return if @raw_fields.include?(field.tag) # first encountered value wins
        @raw_fields[field.tag] = field.value

        return unless tag = TAG_MAPPING[@type][field.tag]
        @fields[tag] = if IFD_TAGS.include?(tag)
                         IFD.new(@data, field.offset, tag)
                       else
                         value = ADAPTERS[tag][field.value]
                         value.kind_of?(Array) && value.size == 1 ? value.first : value
                       end
      end
    end

    class Field # :nodoc:
      attr_reader :tag, :offset, :value

      def initialize(data, pos)
        @tag, count, @offset = data.readshort(pos), data.readlong(pos + 4), data.readlong(pos + 8)
        @type = data.readshort(pos + 2)

        case @type
        when 1 # byte
          len, pack = count, proc { |d| d }
        when 6 # signed byte
          len, pack = count, proc { |d| sign_byte(d) }
        when 2 # ascii
          len, pack = count, proc { |d| d.unpack('Z*') }
        when 3 # short
          len, pack = count * 2, proc { |d| d.unpack(data.short + '*') }
        when 8 # signed short
          len, pack = count * 2, proc { |d| d.unpack(data.short + '*').map{|n| sign_short(n)} }
        when 4 # long
          len, pack = count * 4, proc { |d| d.unpack(data.long + '*') }
        when 9 # signed long
          len, pack = count * 4, proc { |d| d.unpack(data.long + '*').map{|n| sign_long(n)} }
        when 7 # undefined
          # UserComment
          if @tag == 0x9286
            len, pack = count, proc { |d| d.strip }
            len -= 8 # reduce to account for first 8 bytes
            start = len > 4 ? @offset + 8 : (pos + 8) # UserComment first 8-bytes is char code
            @value = [pack[data[start..(start + len - 1)]]].flatten
          end
        when 5 # unsigned rational
          len, pack = count * 8, proc do |d|
            rationals = []
            d.unpack(data.long + '*').each_slice(2) do |f|
              rationals << rational(*f)
            end
            rationals
          end
        when 10 # signed rational
          len, pack = count * 8, proc do |d|
            rationals = []
            d.unpack(data.long + '*').map{|n| sign_long(n)}.each_slice(2) do |f|
              rationals << rational(*f)
            end
            rationals
          end
        when 11 # float
          len, pack = count * 4, proc { |d| d.unpack(data.float + '*') }
        when 12 # double
          len, pack = count * 8, proc { |d| d.unpack(data.double + '*') }
        else
          return
        end

        if len && pack && @type != 7
          start = len > 4 ? @offset : (pos + 8)
          d = data[start..(start + len - 1)]
          @value = d && [pack[d]].flatten
        end
      end

    private
      def sign_byte(n)
        (n & 0x80) != 0 ? n - 0x100 : n
      end

      def sign_short(n)
        (n & 0x8000) != 0 ? n - 0x10000 : n
      end

      def sign_long(n)
        (n & 0x80000000) != 0 ? n - 0x100000000 : n
      end

      def rational(n, d)
        if d == 0 # allow NaN and Infinity
          n.to_f.quo(d)
        else
          Rational.respond_to?(:reduce) ? Rational.reduce(n, d) : n.quo(d)
        end
      end
    end

    class Data #:nodoc:
      attr_reader :short, :long, :float, :double, :file

      def initialize(file)
        @io = file.respond_to?(:read) ? file : (@file = File.open(file, 'rb'))
        @buffer = ''
        @pos = 0

        case self[0..1]
        when 'II'; @short, @long, @float, @double = 'v', 'V', 'e', 'E'
        when 'MM'; @short, @long, @float, @double = 'n', 'N', 'g', 'G'
        else
          raise MalformedTIFF, "no byte order information found"
        end
      end

      def self.open(file, &block)
        data = new(file)
        yield data
      ensure
        data && data.file && data.file.close
      end

      def [](pos)
        unless pos.respond_to?(:begin) && pos.respond_to?(:end)
          pos = pos..pos
        end

        if pos.begin < @pos || pos.end >= @pos + @buffer.size
          read_for(pos)
        end

        @buffer && @buffer[(pos.begin - @pos)..(pos.end - @pos)]
      end

      def readshort(pos)
        self[pos..(pos + 1)].unpack(@short)[0]
      end

      def readlong(pos)
        self[pos..(pos + 3)].unpack(@long)[0]
      end

      def size
        @io.seek(0, IO::SEEK_END)
        @io.pos
      end

    private
      def read_for(pos)
        @io.seek(@pos = pos.begin)
        @buffer = @io.read([pos.end - pos.begin, 4096].max)
      end
    end
  end
end
