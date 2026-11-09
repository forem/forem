class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter  # limits size to 4096x4096
  include CarrierWave::MiniMagick   # adds processing operations

  EXTENSION_ALLOWLIST = %w[jpg jpeg jpe gif png ico bmp dng webp].freeze
  FRAME_MAX = 500
  FRAME_STRIP_MAX = 150

  # JPEG markers to strip (APP1..APP13, APP15, and COM), preserving APP0 (JFIF) and APP14 (Adobe).
  JPEG_METADATA_MARKERS = ((0xE1..0xED).to_a + [0xEF, 0xFE]).freeze
  JPEG_STANDALONE_MARKERS = ([0x01] + (0xD0..0xD8).to_a).freeze
  JPEG_SCAN_TERMINATORS = [0xDA, 0xD9].freeze
  PNG_SIGNATURE = "\x89PNG\r\n\x1A\n".b.freeze
  PNG_METADATA_CHUNKS = %w[tEXt zTXt iTXt tIME].map(&:b).freeze
  PNG_DELEGATED_CHUNKS = %w[eXIf acTL].map(&:b).freeze

  process :validate_frame_count
  process :strip_exif

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def size_range
    1..(25.megabytes)
  end

  # Avoid triggering a synchronous S3 HEAD request when checking `#blank?` / `#present?`
  # (e.g. inside ActiveModel::EachValidator#validate or view/controller presence checks).
  def blank?
    return true if file.nil?
    return file.path.blank? if file.is_a?(CarrierWave::Storage::Fog::File)

    file.blank?
  end

  protected

  def strip_exif
    return if file.content_type&.include?("svg")

    path = current_path
    frames = frame_count
    return if frames > FRAME_STRIP_MAX && !block_given?
    return if !block_given? && strip_metadata_in_place(path)

    image = ::MiniMagick::Image.new(path)
    if frames <= FRAME_STRIP_MAX
      image.combine_options do |b|
        b.auto_orient
        b.strip
      end
    else
      image.auto_orient
    end

    if block_given?
      image = yield(image)
      FileUtils.mv(image.path, path) if image&.path && image.path != path
    end
  rescue StandardError => e
    Rails.logger.error("Error stripping EXIF data: #{e}")
  end

  def validate_frame_count
    begin
      return unless frame_count(MiniMagick::Image.new(file.path)) > FRAME_MAX
    rescue Timeout::Error
      raise CarrierWave::IntegrityError, I18n.t("uploaders.base_uploader.timeout")
    end

    raise CarrierWave::IntegrityError,
          I18n.t("uploaders.base_uploader.too_many_frames", frame_max: FRAME_MAX)
  end

  private

  def frame_count(image = nil)
    target_path = image ? image.path : file.path
    @frame_counts ||= {}
    return @frame_counts[target_path] if @frame_counts.key?(target_path)

    image ||= MiniMagick::Image.new(target_path)
    @frame_counts[target_path] = if FastImage.animated?(target_path)
                                   image.identify(&:ping).lines.count
                                 else
                                   1
                                 end
  end

  # Strips metadata at the container byte level for non-rotated JPEGs and standard PNGs,
  # avoiding spawning ImageMagick subprocesses or re-encoding pixel streams.
  def strip_metadata_in_place(path)
    fast_image = FastImage.new(path)
    case fast_image.type
    when :jpeg
      return false if (fast_image.orientation || 1) > 1

      strip_jpeg_metadata_in_place(path)
    when :png
      strip_png_metadata_in_place(path)
    else
      false
    end
  rescue StandardError
    false
  end

  def strip_jpeg_metadata_in_place(path)
    result = File.open(path, "rb") { |io| parse_jpeg_segments(io) }
    return false unless result
    return true if result == :unchanged

    header_out, scan_data = result
    File.open(path, "wb") do |io|
      io.write(header_out)
      io.write(scan_data)
    end
    true
  end

  def parse_jpeg_segments(io)
    file_size = io.size
    return unless file_size >= 4 && io.read(2) == "\xFF\xD8".b

    header_out = "\xFF\xD8".b
    dropped = false

    while io.pos < file_size
      marker = next_jpeg_marker(io, file_size)
      return unless marker

      if JPEG_SCAN_TERMINATORS.include?(marker)
        return :unchanged unless dropped

        header_out << "\xFF".b << marker.chr
        return [header_out, io.read]
      end

      if JPEG_STANDALONE_MARKERS.include?(marker)
        header_out << "\xFF".b << marker.chr
        next
      end

      segment_dropped = process_jpeg_segment(io, file_size, marker, header_out)
      return if segment_dropped.nil?

      dropped ||= segment_dropped
    end
    nil
  end

  def next_jpeg_marker(io, file_size)
    b = io.getbyte
    return unless b == 0xFF

    b = io.getbyte while b == 0xFF && io.pos < file_size
    b unless b.nil? || b == 0xFF
  end

  def process_jpeg_segment(io, file_size, marker, header_out)
    len_bytes = io.read(2)
    return unless len_bytes&.bytesize == 2

    payload_len = len_bytes.unpack1("n") - 2
    return if payload_len.negative? || io.pos + payload_len > file_size

    if JPEG_METADATA_MARKERS.include?(marker)
      io.seek(payload_len, IO::SEEK_CUR)
      true
    else
      payload = io.read(payload_len)
      return unless payload&.bytesize == payload_len

      header_out << "\xFF".b << marker.chr << len_bytes << payload
      false
    end
  end

  def strip_png_metadata_in_place(path)
    File.open(path, "rb") do |io|
      chunks_to_keep, dropped = scan_png_chunks(io)
      return false unless chunks_to_keep
      return true unless dropped

      out = String.new(PNG_SIGNATURE, capacity: io.size)
      chunks_to_keep.each do |chunk_pos, chunk_len|
        io.seek(chunk_pos, IO::SEEK_SET)
        out << io.read(chunk_len)
      end
      File.binwrite(path, out)
    end
    true
  end

  def scan_png_chunks(io)
    file_size = io.size
    return unless file_size >= 8 && io.read(8) == PNG_SIGNATURE

    chunks_to_keep = []
    dropped = false
    pos = 8

    while pos + 12 <= file_size
      header = io.read(8)
      return unless header&.bytesize == 8

      total = 12 + header.byteslice(0, 4).unpack1("N")
      ctype = header.byteslice(4, 4)
      return if pos + total > file_size || PNG_DELEGATED_CHUNKS.include?(ctype)

      if PNG_METADATA_CHUNKS.include?(ctype)
        dropped = true
      else
        chunks_to_keep << [pos, total]
      end

      pos += total
      break if ctype == "IEND".b

      io.seek(pos, IO::SEEK_SET)
    end

    [chunks_to_keep, dropped] if pos == file_size
  end
end
