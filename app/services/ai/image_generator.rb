require "base64"
require "tempfile"

module Ai
  ##
  # Generates images using Gemini's image generation capabilities (Nano Banana).
  # Takes a text prompt and optionally input images to create, edit, or compose visuals.
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
    GenerationResult = Struct.new(:url, :text_response, keyword_init: true)

    GEMINI_IMAGE_MODEL = "gemini-2.5-flash-image".freeze
    DEFAULT_API_KEY = ENV["GEMINI_API_KEY"].freeze

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

    include HTTParty
    base_uri "https://generativelanguage.googleapis.com/v1beta"

    # @param prompt [String] The text prompt describing the desired image
    # @param input_images [Array<String>, nil] Optional paths to input images for editing/composition
    # @param aspect_ratio [String, nil] Optional aspect ratio (e.g., "16:9", "1:1")
    # @param response_modalities [Array<String>] Output types - ['Image', 'Text'] or ['Image']
    # @param api_key [String] Gemini API key (defaults to ENV['GEMINI_API_KEY'])
    def initialize(prompt, input_images: nil, aspect_ratio: nil, response_modalities: ["Image", "Text"], api_key: DEFAULT_API_KEY)
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
      @options = {
        headers: {
          "Content-Type" => "application/json"
        }
      }
    end

    ##
    # Generates the image and uploads it to storage.
    # Returns nil if generation fails.
    #
    # @return [GenerationResult, nil] A struct containing the image URL and any text response
    def generate
      Rails.logger.info "==== Starting Gemini Image Generation ===="
      Rails.logger.info "Prompt: #{@prompt[0..100]}#{@prompt.length > 100 ? '...' : ''}"
      Rails.logger.info "Input images: #{@input_images&.count || 0}"
      Rails.logger.info "Aspect ratio: #{@aspect_ratio || 'default'}"

      Rails.logger.info "[1/4] Building API request..."
      request_body = build_request_body

      Rails.logger.info "[2/4] Calling Gemini API..."
      response = call_gemini_api(request_body)

      Rails.logger.info "[3/4] Extracting image data..."
      image_data, text_response = extract_image_data(response)

      unless image_data
        Rails.logger.warn "No image data in response"
        return nil
      end

      Rails.logger.info "[4/4] Uploading image to storage..."
      image_url = upload_image(image_data)

      unless image_url
        Rails.logger.error "Failed to upload image"
        return nil
      end

      Rails.logger.info "✓ Image generated successfully: #{image_url}"
      Rails.logger.info "==== Image Generation Complete ===="

      GenerationResult.new(url: image_url, text_response: text_response)
    rescue StandardError => e
      Rails.logger.error "✗ Image generation failed: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      nil
    end

    private

    attr_reader :prompt, :input_images, :aspect_ratio, :response_modalities, :api_key, :options

    ##
    # Builds the request body for the Gemini API
    #
    # @return [Hash] The request body
    def build_request_body
      body = {
        contents: build_contents
      }

      # Add generation config if we have aspect ratio or response modality settings
      if aspect_ratio || response_modalities != ["Image", "Text"]
        body[:generationConfig] = build_generation_config
      end

      body
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
    # @return [Hash] Generation config with optional aspect ratio and response modalities
    def build_generation_config
      config = {}

      if response_modalities != ["Image", "Text"]
        config[:responseModalities] = response_modalities
      end

      if aspect_ratio
        config[:imageConfig] = {
          aspectRatio: aspect_ratio
        }
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
    # @return [Hash] Parsed API response
    def call_gemini_api(request_body)
      api_url = "/models/#{GEMINI_IMAGE_MODEL}:generateContent?key=#{api_key}"
      options[:body] = request_body.to_json

      response = self.class.post(api_url, options)

      unless response.success?
        error_info = response.parsed_response["error"] || { "message" => "Unknown API Error" }
        raise "API Error: #{response.code} - #{error_info['message']}"
      end

      response.parsed_response
    end

    ##
    # Extracts image data and optional text from the API response
    #
    # @param response [Hash] The parsed API response
    # @return [Array<String, String>] Tuple of [image_data, text_response]
    def extract_image_data(response)
      unless response.key?("candidates")
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
        Rails.logger.error "No parts found in candidate content"
        return [nil, nil]
      end

      image_data = nil
      text_response = nil

      # Extract both image and text from parts
      parts.each do |part|
        if part["inlineData"]
          # Found image data
          image_data = part.dig("inlineData", "data")
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
      tempfile = Tempfile.new(["gemini_generated", ".png"])
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
          tempfile.unlink if File.exist?(tempfile.path)
          Rails.logger.debug "Cleaned up temporary image file: #{tempfile.path}"
        rescue StandardError => cleanup_error
          Rails.logger.warn "Failed to cleanup temp file: #{cleanup_error.message}"
        end
      end
    end
  end
end

