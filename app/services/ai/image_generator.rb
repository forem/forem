require "base64"
require "tempfile"

module Ai
  ##
  # Generates images using Gemini's image generation capabilities (Nano Banana).
  # Takes a text prompt and optionally input images to create, edit, or compose visuals.
  #
  # Requests are image-only with minimal thinking to keep latency low. When an
  # attempt comes back without an image for a transient reason (the model replied
  # with text only, NO_IMAGE, a 429/5xx, a network error), it is retried once on
  # the fallback model. Refusals (safety or prohibited content) are not retried.
  # After a failed #generate, #failure_reason says which kind of failure it was.
  #
  # @example Generate an image from text
  #   generator = Ai::ImageGenerator.new("A photorealistic cat eating a banana")
  #   result = generator.generate
  #   puts result.url if result
  #
  # @example Edit an existing image
  #   generator = Ai::ImageGenerator.new(
  #     "Add a wizard hat to this cat",
  #     input_images: ["/path/to/cat.jpg"]
  #   )
  #   result = generator.generate
  #
  # @example Configure aspect ratio
  #   generator = Ai::ImageGenerator.new(
  #     "A landscape of mountains",
  #     aspect_ratio: "16:9"
  #   )
  #   result = generator.generate
  class ImageGenerator
    VERSION = "2.0"
    GenerationResult = Struct.new(:url, :text_response, keyword_init: true)

    GEMINI_IMAGE_MODEL = ENV.fetch("GEMINI_IMAGE_MODEL", "gemini-nano-banana-2.1").freeze
    # Used for the retry after a transient failure. Blank disables the retry.
    GEMINI_IMAGE_FALLBACK_MODEL = ENV.fetch("GEMINI_IMAGE_FALLBACK_MODEL", "gemini-3.1-flash-lite-image").freeze
    # Nano Banana 2.1 defaults to "medium"; "minimal" keeps generation fast.
    THINKING_LEVEL = ENV.fetch("GEMINI_IMAGE_THINKING_LEVEL", "minimal").freeze
    DEFAULT_API_KEY = ENV["GEMINI_API_KEY"].freeze

    # Candidate finish reasons that mean the model declined to draw the request.
    # Retrying these wastes time and money, and the user needs to change the prompt.
    REFUSAL_FINISH_REASONS = %w[
      SAFETY IMAGE_SAFETY PROHIBITED_CONTENT IMAGE_PROHIBITED_CONTENT
      BLOCKLIST SPII RECITATION IMAGE_RECITATION
    ].freeze
    RETRYABLE_STATUS_CODES = [408, 429, 500, 502, 503, 504].freeze
    # Gemini 3 image models return JPEG, older ones PNG; the stored file keeps the real type.
    IMAGE_EXTENSIONS = { "image/jpeg" => ".jpg", "image/png" => ".png", "image/webp" => ".webp" }.freeze

    # Valid aspect ratios and their corresponding resolutions
    VALID_ASPECT_RATIOS = {
      "1:1" => "1024x1024",
      "2:3" => "832x1248",
      "3:2" => "1248x832",
      "3:4" => "864x1184",
      "4:3" => "1184x864",
      "4:5" => "896x1152",
      "5:4" => "1152x896",
      "9:16" => "768x1344",
      "16:9" => "1344x768",
      "21:9" => "1536x672"
    }.freeze

    # Raised for a non-success HTTP response from the Gemini API.
    class ApiError < StandardError
      attr_reader :status_code

      def initialize(message, status_code:)
        super(message)
        @status_code = status_code
      end
    end

    include HTTParty
    base_uri "https://generativelanguage.googleapis.com/v1beta"

    # Why the last #generate returned nil: :refused (the model declined the
    # prompt), :transient (still no image after the retry: a text-only reply,
    # NO_IMAGE, or a 429/5xx or network error), or :error (a non-retryable API
    # error or an upload failure).
    attr_reader :failure_reason

    # @param prompt [String] The text prompt describing the desired image
    # @param input_images [Array<String>, nil] Optional paths to input images for editing/composition
    # @param aspect_ratio [String, nil] Optional aspect ratio (e.g., "16:9", "1:1")
    # @param response_modalities [Array<String>] Output types - ['Image'] (default) or ['Image', 'Text']
    # @param api_key [String] Gemini API key (defaults to ENV['GEMINI_API_KEY'])
    # @param affected_user [User, nil] The user executing the action
    def initialize(prompt, input_images: nil, aspect_ratio: nil, response_modalities: %w[Image],
                   api_key: DEFAULT_API_KEY, affected_user: nil)
      raise ArgumentError, "Prompt cannot be blank" if prompt.blank?
      raise ArgumentError, "API key cannot be nil" if api_key.nil? && !Rails.env.test?

      if aspect_ratio && !VALID_ASPECT_RATIOS.key?(aspect_ratio)
        raise ArgumentError, "Invalid aspect ratio. Must be one of: #{VALID_ASPECT_RATIOS.keys.join(', ')}"
      end

      @prompt = prompt
      @input_images = input_images
      @aspect_ratio = aspect_ratio
      @response_modalities = response_modalities
      @api_key = api_key
      @affected_user = affected_user
      @options = {
        headers: {
          "Content-Type" => "application/json"
        }
      }
    end

    ##
    # Generates the image and uploads it to storage.
    # Returns nil if generation fails; #failure_reason then says why.
    #
    # @return [GenerationResult, nil] A struct containing the image URL and any text response
    def generate
      @failure_reason = nil
      @image_mime_type = nil
      Rails.logger.info "==== Starting Gemini Image Generation ===="
      Rails.logger.info "Prompt: #{@prompt[0..100]}#{@prompt.length > 100 ? '...' : ''}"
      Rails.logger.info "Input images: #{@input_images&.count || 0}"
      Rails.logger.info "Aspect ratio: #{@aspect_ratio || 'default'}"

      Rails.logger.info "[1/2] Requesting image from Gemini..."
      image_data, text_response = request_image

      unless image_data
        Rails.logger.warn "No image data in response"
        return
      end

      Rails.logger.info "[2/2] Uploading image to storage..."
      image_url = upload_image(image_data)

      unless image_url
        Rails.logger.error "Failed to upload image"
        @failure_reason = :error
        return
      end

      Rails.logger.info "✓ Image generated successfully: #{image_url}"
      Rails.logger.info "==== Image Generation Complete ===="

      GenerationResult.new(url: image_url, text_response: text_response)
    rescue StandardError => e
      Rails.logger.error "✗ Image generation failed: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      @failure_reason = :error
      nil
    end

    private

    attr_reader :prompt, :input_images, :aspect_ratio, :response_modalities, :api_key, :options, :affected_user

    ##
    # Tries the primary model, then the fallback model when the first attempt
    # failed for a transient reason. Sets @failure_reason when no image results.
    #
    # @return [Array<String, String>] Tuple of [image_data, text_response]
    def request_image
      models = [GEMINI_IMAGE_MODEL, GEMINI_IMAGE_FALLBACK_MODEL.presence].compact.uniq

      models.each_with_index do |model, attempt|
        image_data, text_response, failure = attempt_generation(model, attempt)
        @failure_reason = failure
        return [image_data, text_response] if image_data

        break unless failure == :transient && attempt < models.size - 1

        Rails.logger.warn "Retrying image generation with #{models[attempt + 1]} (#{model} returned no image)"
      end

      [nil, nil]
    end

    ##
    # Makes one generation request and classifies the outcome.
    #
    # @return [Array] [image_data, text_response, failure] where failure is nil,
    #   :refused, :transient (retryable), or :error (not retryable)
    def attempt_generation(model, attempt)
      response = call_gemini_api(build_request_body(model), model: model, retry_count: attempt)
      image_data, text_response = extract_image_data(response)
      return [image_data, text_response, nil] if image_data

      [nil, text_response, refusal?(response) ? :refused : :transient]
    rescue ApiError => e
      Rails.logger.error "✗ Image generation failed: #{e.message}"
      [nil, nil, RETRYABLE_STATUS_CODES.include?(e.status_code) ? :transient : :error]
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError => e
      Rails.logger.error "✗ Image generation failed: #{e.class} - #{e.message}"
      [nil, nil, :transient]
    end

    def refusal?(response)
      return true if response.dig("promptFeedback", "blockReason").present?

      REFUSAL_FINISH_REASONS.include?(response.dig("candidates", 0, "finishReason"))
    end

    ##
    # Builds the request body for the Gemini API
    #
    # @param model [String] The model the request is for
    # @return [Hash] The request body
    def build_request_body(model)
      {
        contents: build_contents,
        generationConfig: build_generation_config(model)
      }
    end

    ##
    # Builds the contents array with text prompt and optional images
    #
    # @return [Array<Hash>] Array of content parts
    def build_contents
      parts = []

      # Add text prompt
      parts << { text: prompt }

      # Add input images if provided (for editing/composition)
      if input_images&.any?
        input_images.each do |image_path|
          image_data = encode_image(image_path)
          mime_type = detect_mime_type(image_path)
          parts << {
            inlineData: {
              mimeType: mime_type,
              data: image_data
            }
          }
        end
      end

      [{ parts: parts }]
    end

    ##
    # Builds the generation configuration
    #
    # @param model [String] The model the request is for
    # @return [Hash] Generation config with response modalities, optional aspect ratio and thinking level
    def build_generation_config(model)
      config = { responseModalities: response_modalities }

      if aspect_ratio
        config[:imageConfig] = {
          aspectRatio: aspect_ratio
        }
      end

      # Gemini 2.x image models reject thinkingLevel, so an env override back to
      # one of them still works.
      if THINKING_LEVEL.present? && !model.start_with?("gemini-2")
        config[:thinkingConfig] = { thinkingLevel: THINKING_LEVEL }
      end

      config
    end

    ##
    # Encodes an image file to base64
    #
    # @param image_path [String] Path to the image file
    # @return [String] Base64 encoded image data
    def encode_image(image_path)
      Base64.strict_encode64(File.read(image_path))
    end

    ##
    # Detects the MIME type from file extension
    #
    # @param image_path [String] Path to the image file
    # @return [String] MIME type
    def detect_mime_type(image_path)
      ext = File.extname(image_path).downcase
      case ext
      when ".jpg", ".jpeg"
        "image/jpeg"
      when ".png"
        "image/png"
      when ".gif"
        "image/gif"
      when ".webp"
        "image/webp"
      else
        "image/jpeg" # default
      end
    end

    ##
    # Calls the Gemini API to generate the image
    #
    # @param request_body [Hash] The request body
    # @param model [String] The model to call
    # @param retry_count [Integer] Which attempt this is, for the audit log
    # @return [Hash] Parsed API response
    # @raise [ApiError] for a non-success response
    def call_gemini_api(request_body, model:, retry_count:)
      api_url = "/models/#{model}:generateContent?key=#{api_key}"
      options[:body] = request_body.to_json

      start_time = Time.now.to_f
      begin
        response = self.class.post(api_url, options)
        latency_ms = ((Time.now.to_f - start_time) * 1000).to_i
        status_code = response.code

        unless response.success?
          error_info = response.parsed_response.is_a?(Hash) && response.parsed_response["error"]
          error_message = "API Error: #{status_code} - #{(error_info || {})['message'] || 'Unknown API Error'}"
        end

        log_audit(response, model: model, retry_count: retry_count, latency_ms: latency_ms,
                            status_code: status_code, error_message: error_message)

        raise ApiError.new(error_message, status_code: status_code) if error_message

        response.parsed_response
      rescue ApiError
        raise
      rescue StandardError => e
        latency_ms ||= ((Time.now.to_f - start_time) * 1000).to_i
        log_audit(nil, model: model, retry_count: retry_count, latency_ms: latency_ms, error_message: e.message)
        raise e
      end
    end

    def log_audit(response, model:, retry_count: 0, latency_ms: nil, status_code: nil, error_message: nil)
      prompt_tokens = response&.parsed_response&.dig("usageMetadata", "promptTokenCount")
      candidates_tokens = response&.parsed_response&.dig("usageMetadata", "candidatesTokenCount")
      total_tokens = response&.parsed_response&.dig("usageMetadata", "totalTokenCount")

      AiAudit.create!(
        ai_model: model,
        wrapper_object_class: self.class.name,
        wrapper_object_version: self.class.const_defined?(:VERSION) ? self.class::VERSION : nil,
        request_body: options[:body],
        response_body: response&.parsed_response,
        retry_count: retry_count,
        affected_user: affected_user,
        prompt_token_count: prompt_tokens,
        candidates_token_count: candidates_tokens,
        total_token_count: total_tokens,
        latency_ms: latency_ms,
        status_code: status_code,
        error_message: error_message,
      )
    rescue StandardError => e
      Rails.logger.error("Failed to log AiAudit: #{e}")
    end

    ##
    # Extracts image data and optional text from the API response.
    # Thought parts are skipped: Gemini 3 image models can emit interim draft
    # images while thinking, and only the final image should be used.
    #
    # @param response [Hash] The parsed API response
    # @return [Array<String, String>] Tuple of [image_data, text_response]
    def extract_image_data(response)
      unless response.is_a?(Hash) && response.key?("candidates")
        Rails.logger.error "Malformed response: 'candidates' key not found"
        return [nil, nil]
      end

      candidate = response["candidates"].first
      unless candidate
        Rails.logger.error "No candidates received from the API"
        return [nil, nil]
      end

      parts = candidate.dig("content", "parts")
      unless parts
        Rails.logger.error "No parts found in candidate content (finishReason: #{candidate['finishReason']})"
        return [nil, nil]
      end

      image_data = nil
      text_response = nil

      # Extract both image and text from parts; the last final image wins
      parts.reject { |part| part["thought"] }.each do |part|
        if part["inlineData"]
          # Found image data
          image_data = part.dig("inlineData", "data")
          @image_mime_type = part.dig("inlineData", "mimeType")
          Rails.logger.info "Found image data (#{image_data&.length || 0} bytes base64)"
        elsif part["text"]
          # Found text response
          text_response = part["text"]
          Rails.logger.info "Found text response: #{text_response[0..100]}#{text_response.length > 100 ? '...' : ''}"
        end
      end

      [image_data, text_response]
    end

    ##
    # Uploads the base64 image data to storage and returns the URL
    #
    # @param image_data [String] Base64 encoded image data
    # @return [String, nil] The URL of the uploaded image, or nil if upload fails
    def upload_image(image_data)
      tempfile = nil

      # Decode base64 data
      decoded_data = Base64.decode64(image_data)

      # Create a temporary file
      tempfile = Tempfile.new(["gemini_generated", IMAGE_EXTENSIONS.fetch(@image_mime_type, ".png")])
      tempfile.binmode
      tempfile.write(decoded_data)
      tempfile.rewind

      # Upload using ArticleImageUploader
      uploader = ArticleImageUploader.new
      uploader.store!(tempfile)
      url = uploader.url

      Rails.logger.info "Image uploaded successfully to: #{url}"

      url
    rescue StandardError => e
      Rails.logger.error "Failed to upload image: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      nil
    ensure
      # Cleanup temp file - ensure it's always deleted
      if tempfile
        begin
          tempfile.close unless tempfile.closed?
          path = tempfile.path
          tempfile.unlink if path && File.exist?(path)
          Rails.logger.debug { "Cleaned up temporary image file: #{path}" }
        rescue StandardError => e
          Rails.logger.warn "Failed to cleanup temp file: #{e.message}"
        end
      end
    end
  end
end
