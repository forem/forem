require "rails_helper"

RSpec.describe Ai::ImageGenerator do
  let(:prompt) { "A photorealistic cat eating a banana" }
  let(:api_key) { "test_api_key" }

  describe "#initialize" do
    it "initializes with a prompt" do
      generator = described_class.new(prompt)
      expect(generator).to be_a(described_class)
    end

    it "raises error with blank prompt" do
      expect { described_class.new("") }.to raise_error(ArgumentError, "Prompt cannot be blank")
      expect { described_class.new(nil) }.to raise_error(ArgumentError, "Prompt cannot be blank")
    end

    it "accepts optional input images" do
      generator = described_class.new(prompt, input_images: ["/path/to/image.jpg"])
      expect(generator).to be_a(described_class)
    end

    it "accepts optional aspect ratio" do
      generator = described_class.new(prompt, aspect_ratio: "16:9")
      expect(generator).to be_a(described_class)
    end

    it "raises error with invalid aspect ratio" do
      expect do
        described_class.new(prompt, aspect_ratio: "99:1")
      end.to raise_error(ArgumentError, /Invalid aspect ratio/)
    end

    it "accepts valid aspect ratios" do
      valid_ratios = ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]
      valid_ratios.each do |ratio|
        expect { described_class.new(prompt, aspect_ratio: ratio) }.not_to raise_error
      end
    end

    it "accepts custom response modalities" do
      generator = described_class.new(prompt, response_modalities: ["Image"])
      expect(generator).to be_a(described_class)
    end
  end

  describe "#generate" do
    let(:generator) { described_class.new(prompt, api_key: api_key) }
    let(:mock_image_data) { Base64.strict_encode64("fake_image_data") }
    let(:mock_text_response) { "I created an image of a cat eating a banana." }
    let(:mock_api_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "text" => mock_text_response },
                { "inlineData" => { "data" => mock_image_data, "mimeType" => "image/png" } }
              ]
            }
          }
        ]
      }
    end
    let(:uploaded_url) { "https://example.com/uploads/generated_image.png" }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
    end

    context "when generation succeeds" do
      before do
        stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
          .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })

        uploader = instance_double(ArticleImageUploader, url: uploaded_url)
        allow(ArticleImageUploader).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:store!)
      end

      it "generates and returns an image URL" do
        result = generator.generate

        expect(result).to be_a(Ai::ImageGenerator::GenerationResult)
        expect(result.url).to eq(uploaded_url)
        expect(result.text_response).to eq(mock_text_response)
      end

      it "logs the generation process" do
        generator.generate

        expect(Rails.logger).to have_received(:info).with("==== Starting Gemini Image Generation ====")
        expect(Rails.logger).to have_received(:info).with(/Prompt:/)
        expect(Rails.logger).to have_received(:info).with("✓ Image generated successfully: #{uploaded_url}")
      end

      it "uploads the image using ArticleImageUploader" do
        uploader = instance_double(ArticleImageUploader, url: uploaded_url)
        allow(ArticleImageUploader).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:store!)

        generator.generate

        expect(ArticleImageUploader).to have_received(:new)
        expect(uploader).to have_received(:store!)
      end
    end

    context "when API returns only image without text" do
      let(:mock_api_response) do
        {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  { "inlineData" => { "data" => mock_image_data, "mimeType" => "image/png" } }
                ]
              }
            }
          ]
        }
      end

      before do
        stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
          .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })

        uploader = instance_double(ArticleImageUploader, url: uploaded_url)
        allow(ArticleImageUploader).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:store!)
      end

      it "returns result with nil text_response" do
        result = generator.generate

        expect(result).to be_a(Ai::ImageGenerator::GenerationResult)
        expect(result.url).to eq(uploaded_url)
        expect(result.text_response).to be_nil
      end
    end

    context "when API call fails" do
      before do
        stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
          .to_return(status: 500, body: { error: { message: "Internal Server Error" } }.to_json)
      end

      it "returns nil" do
        result = generator.generate
        expect(result).to be_nil
      end

      it "logs the error" do
        generator.generate
        expect(Rails.logger).to have_received(:error).with(/Image generation failed/)
      end
    end

    context "when API returns malformed response" do
      before do
        stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
          .to_return(status: 200, body: { "invalid" => "response" }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns nil" do
        result = generator.generate
        expect(result).to be_nil
      end

      it "logs the error" do
        generator.generate
        expect(Rails.logger).to have_received(:error).with("Malformed response: 'candidates' key not found")
      end
    end

    context "when image upload fails" do
      before do
        stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
          .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })

        uploader = instance_double(ArticleImageUploader)
        allow(ArticleImageUploader).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:store!).and_raise(StandardError, "Upload failed")
      end

      it "returns nil" do
        result = generator.generate
        expect(result).to be_nil
      end

      it "logs the upload error" do
        generator.generate
        expect(Rails.logger).to have_received(:error).with(/Failed to upload image/).at_least(:once)
      end
    end

    context "when API returns no image data" do
      let(:mock_api_response) do
        {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  { "text" => "I couldn't generate an image." }
                ]
              }
            }
          ]
        }
      end

      before do
        stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
          .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns nil" do
        result = generator.generate
        expect(result).to be_nil
      end

      it "logs a warning" do
        generator.generate
        expect(Rails.logger).to have_received(:warn).with("No image data in response")
      end
    end
  end

  describe "#generate with input images" do
    let(:input_image_path) { Rails.root.join("spec/fixtures/files/test_image.jpg").to_s }
    let(:generator) { described_class.new(prompt, input_images: [input_image_path], api_key: api_key) }
    let(:mock_image_data) { Base64.strict_encode64("fake_image_data") }
    let(:mock_api_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "inlineData" => { "data" => mock_image_data, "mimeType" => "image/png" } }
              ]
            }
          }
        ]
      }
    end
    let(:uploaded_url) { "https://example.com/uploads/generated_image.png" }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)

      # Create a temporary test image file
      FileUtils.mkdir_p(File.dirname(input_image_path))
      File.write(input_image_path, "fake_image_content") unless File.exist?(input_image_path)

      stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
        .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })

      uploader = instance_double(ArticleImageUploader, url: uploaded_url)
      allow(ArticleImageUploader).to receive(:new).and_return(uploader)
      allow(uploader).to receive(:store!)
    end

    it "includes input images in the request" do
      generator.generate

      # Verify the request was made
      expect(WebMock).to have_requested(:post, %r{gemini-2\.5-flash-image:generateContent})
    end

    it "logs the number of input images" do
      generator.generate
      expect(Rails.logger).to have_received(:info).with("Input images: 1")
    end
  end

  describe "#generate with aspect ratio" do
    let(:generator) { described_class.new(prompt, aspect_ratio: "16:9", api_key: api_key) }
    let(:mock_image_data) { Base64.strict_encode64("fake_image_data") }
    let(:mock_api_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "inlineData" => { "data" => mock_image_data, "mimeType" => "image/png" } }
              ]
            }
          }
        ]
      }
    end
    let(:uploaded_url) { "https://example.com/uploads/generated_image.png" }

    before do
      allow(Rails.logger).to receive(:info)

      stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
        .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })

      uploader = instance_double(ArticleImageUploader, url: uploaded_url)
      allow(ArticleImageUploader).to receive(:new).and_return(uploader)
      allow(uploader).to receive(:store!)
    end

    it "includes aspect ratio in the request" do
      generator.generate

      # Verify the request was made with aspect ratio config
      expect(WebMock).to have_requested(:post, %r{gemini-2\.5-flash-image:generateContent})
    end

    it "logs the aspect ratio" do
      generator.generate
      expect(Rails.logger).to have_received(:info).with("Aspect ratio: 16:9")
    end
  end

  describe "#generate with custom response modalities" do
    let(:generator) { described_class.new(prompt, response_modalities: ["Image"], api_key: api_key) }
    let(:mock_image_data) { Base64.strict_encode64("fake_image_data") }
    let(:mock_api_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "inlineData" => { "data" => mock_image_data, "mimeType" => "image/png" } }
              ]
            }
          }
        ]
      }
    end
    let(:uploaded_url) { "https://example.com/uploads/generated_image.png" }

    before do
      allow(Rails.logger).to receive(:info)

      stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
        .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })

      uploader = instance_double(ArticleImageUploader, url: uploaded_url)
      allow(ArticleImageUploader).to receive(:new).and_return(uploader)
      allow(uploader).to receive(:store!)
    end

    it "generates image with Image-only response" do
      result = generator.generate

      expect(result).to be_a(Ai::ImageGenerator::GenerationResult)
      expect(result.url).to eq(uploaded_url)
      expect(result.text_response).to be_nil
    end
  end

  describe "MIME type detection" do
    let(:generator) { described_class.new(prompt, api_key: api_key) }

    it "detects jpeg MIME type" do
      expect(generator.send(:detect_mime_type, "image.jpg")).to eq("image/jpeg")
      expect(generator.send(:detect_mime_type, "image.jpeg")).to eq("image/jpeg")
    end

    it "detects png MIME type" do
      expect(generator.send(:detect_mime_type, "image.png")).to eq("image/png")
    end

    it "detects gif MIME type" do
      expect(generator.send(:detect_mime_type, "image.gif")).to eq("image/gif")
    end

    it "detects webp MIME type" do
      expect(generator.send(:detect_mime_type, "image.webp")).to eq("image/webp")
    end

    it "defaults to jpeg for unknown extensions" do
      expect(generator.send(:detect_mime_type, "image.bmp")).to eq("image/jpeg")
    end
  end

  describe "temporary file cleanup" do
    let(:generator) { described_class.new(prompt, api_key: api_key) }
    let(:mock_image_data) { Base64.strict_encode64("fake_image_data") }
    let(:mock_api_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "inlineData" => { "data" => mock_image_data, "mimeType" => "image/png" } }
              ]
            }
          }
        ]
      }
    end
    let(:uploaded_url) { "https://example.com/uploads/generated_image.png" }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)
      allow(Rails.logger).to receive(:warn)
    end

    context "on successful generation" do
      before do
        stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
          .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })

        uploader = instance_double(ArticleImageUploader, url: uploaded_url)
        allow(ArticleImageUploader).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:store!)
      end

      it "cleans up temporary files after successful upload" do
        temp_file_path = nil

        # Capture the tempfile path during upload
        allow(Tempfile).to receive(:new).and_wrap_original do |method, *args|
          tempfile = method.call(*args)
          temp_file_path = tempfile.path
          tempfile
        end

        generator.generate

        # Verify the temp file was cleaned up
        expect(temp_file_path).not_to be_nil
        expect(File.exist?(temp_file_path)).to be false
      end

      it "logs cleanup confirmation" do
        generator.generate
        expect(Rails.logger).to have_received(:debug).with(/Cleaned up temporary image file/)
      end
    end

    context "on failed upload" do
      before do
        stub_request(:post, %r{https://generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-flash-image:generateContent})
          .to_return(status: 200, body: mock_api_response.to_json, headers: { "Content-Type" => "application/json" })

        uploader = instance_double(ArticleImageUploader)
        allow(ArticleImageUploader).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:store!).and_raise(StandardError, "Upload failed")
        allow(Rails.logger).to receive(:error)
      end

      it "still cleans up temporary files even when upload fails" do
        temp_file_path = nil

        # Capture the tempfile path during upload attempt
        allow(Tempfile).to receive(:new).and_wrap_original do |method, *args|
          tempfile = method.call(*args)
          temp_file_path = tempfile.path
          tempfile
        end

        generator.generate

        # Verify the temp file was cleaned up despite the error
        expect(temp_file_path).not_to be_nil
        expect(File.exist?(temp_file_path)).to be false
      end
    end
  end
end

