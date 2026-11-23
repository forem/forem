# Safely inspects remote image dimensions and type by fetching bounded header
# bytes through SafeHttp (enforcing http/https schemes, public-IP-only DNS
# resolution, IP pinning against DNS rebinding, and redirect hop validation)
# before parsing in-memory with FastImage.
class SafeFastImage
  DEFAULT_TIMEOUT = 10
  MAX_BYTES = 512 * 1024
  MAX_NON_2XX_BYTES = 64 * 1024

  Result = Data.define(:size, :type)
  EMPTY_RESULT = Result.new(size: nil, type: nil).freeze

  def self.size(url, timeout: DEFAULT_TIMEOUT, http_header: nil)
    new(url, timeout: timeout, http_header: http_header).size
  end

  # Inspects an already-verified local file (e.g. CarrierWave::SanitizedFile).
  # Do not pass untrusted user input here; use `.new` or `.size` for URLs.
  def self.from_file(path)
    return EMPTY_RESULT if path.blank?

    image = FastImage.new(path)
    Result.new(size: image.size, type: image.type)
  rescue FastImage::FastImageException, SystemCallError
    EMPTY_RESULT
  end

  def initialize(url, timeout: DEFAULT_TIMEOUT, http_header: nil)
    @result = inspect_remote(url, timeout: timeout, http_header: http_header)
  end

  def size
    @result.size
  end

  def type
    @result.type
  end

  private

  def inspect_remote(url, timeout:, http_header:)
    return EMPTY_RESULT if url.blank? || timeout.nil? || timeout <= 0

    bytes = fetch_image_bytes(url, timeout: timeout, http_header: http_header)
    return EMPTY_RESULT if bytes.blank?

    image = FastImage.new(StringIO.new(bytes))
    Result.new(size: image.size, type: image.type)
  rescue SafeHttp::BlockedUrlError, SafeHttp::TooManyRedirectsError => e
    Rails.logger.warn("[SafeFastImage] Rejected image request (#{e.class.name})") if defined?(Rails) && Rails.logger
    EMPTY_RESULT
  rescue StandardError
    EMPTY_RESULT
  end

  def fetch_image_bytes(url, timeout:, http_header:)
    state = { buffer: +"".b, non_2xx_bytes: 0, deadline: monotonic_now + timeout }
    options = build_request_options(timeout, http_header, state[:deadline])

    aborted = true
    catch(:abort_fetch) do
      catch(:max_bytes_reached) do
        SafeHttp.get(url, **options) { |fragment| consume_fragment(fragment, state) }
      end
      aborted = false
    end

    aborted ? nil : state[:buffer]
  end

  def build_request_options(timeout, http_header, deadline)
    options = {
      timeout: timeout,
      stream_body: true,
      http_proxyaddr: nil,
      validate_url: ->(_hop_url) { check_deadline!(deadline) }
    }
    options[:headers] = http_header if http_header.present?
    options
  end

  def consume_fragment(fragment, state)
    check_deadline!(state[:deadline])
    return append_image_bytes(fragment, state[:buffer]) if fragment.code.between?(200, 299)

    throw :abort_fetch unless fragment.code.between?(300, 399)

    state[:non_2xx_bytes] += fragment.bytesize
    throw :abort_fetch if state[:non_2xx_bytes] > MAX_NON_2XX_BYTES
  end

  def append_image_bytes(fragment, buffer)
    remaining = MAX_BYTES - buffer.bytesize
    buffer << fragment.b.byteslice(0, remaining) if remaining.positive?
    throw :max_bytes_reached if buffer.bytesize >= MAX_BYTES
  end

  def check_deadline!(deadline)
    throw :abort_fetch if monotonic_now >= deadline

    true
  end

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
