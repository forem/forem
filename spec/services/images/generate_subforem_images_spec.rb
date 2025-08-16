require "rails_helper"

RSpec.describe Images::GenerateSubforemImages do
  let(:subforem) { create(:subforem) }
  let(:image_url) { "https://example.com/logo.png" }
  let(:background_url) { "https://example.com/background.png" }
  let(:service) { described_class.new(subforem.id, image_url) }

  describe ".call" do
    it "creates a new instance and calls it" do
      expect(described_class).to receive(:new).with(subforem.id, image_url, nil).and_return(service)
      expect(service).to receive(:call)
      described_class.call(subforem.id, image_url)
    end

    it "creates a new instance with background URL and calls it" do
      expect(described_class).to receive(:new).with(subforem.id, image_url, background_url).and_return(service)
      expect(service).to receive(:call)
      described_class.call(subforem.id, image_url, background_url)
    end
  end

  describe "#call" do
    let(:mock_source_image) { double }
    let(:mock_background_image) { double }
    let(:mock_result_image) { double }
    let(:mock_uploader) { double }
    let(:uploaded_url) { "https://cdn.example.com/uploaded_image.png" }

    before do
      # Stub web requests to prevent real HTTP calls
      stub_request(:get, "https://cdn.example.com/uploaded_image.png").to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://cdn.example.com/resized.png").to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://cdn.example.com/social.png").to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://cdn.example.com/uploaded.png").to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://cdn.example.com/integration.png").to_return(status: 200, body: "", headers: {})

      allow(MiniMagick::Image).to receive(:open).with(image_url).and_return(mock_source_image)
      allow(MiniMagick::Image).to receive(:open).with(Images::TEMPLATE_PATH).and_return(mock_background_image)
      allow(mock_source_image).to receive(:resize)
      allow(mock_source_image).to receive(:write)
      allow(mock_background_image).to receive(:composite).and_return(mock_result_image)
      allow(mock_result_image).to receive(:write)
      allow(ArticleImageUploader).to receive(:new).and_return(mock_uploader)
      allow(mock_uploader).to receive(:store!)
      allow(mock_uploader).to receive(:url).and_return(uploaded_url)
      allow(Settings::General).to receive(:set_resized_logo)
      allow(Settings::General).to receive(:set_favicon_url)
      allow(Settings::General).to receive(:set_main_social_image)
      allow(Settings::General).to receive(:set_logo_png)
      allow(Tempfile).to receive(:new).and_return(double(close: nil, unlink: nil, path: "/tmp/test.png"))
    end

    context "when all operations succeed" do
      it "generates and saves all images successfully" do
        service.call

        expect(Settings::General).to have_received(:set_resized_logo).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_favicon_url).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_main_social_image).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_logo_png).with(uploaded_url, subforem_id: subforem.id)
      end

      it "resizes the source image correctly for logo and favicon" do
        service.call

        expect(mock_source_image).to have_received(:resize).with("100x100").twice
      end

      it "resizes the source image correctly for logo png" do
        service.call

        expect(mock_source_image).to have_received(:resize).with("512x512")
      end

      it "creates the social image with correct dimensions and positioning" do
        service.call

        expect(MiniMagick::Image).to have_received(:open).with(Images::TEMPLATE_PATH)
        expect(mock_source_image).to have_received(:resize).with("300x300")
        expect(mock_background_image).to have_received(:composite).with(mock_source_image)
      end
    end

    context "when background URL is provided" do
      let(:service_with_background) { described_class.new(subforem.id, image_url, background_url) }
      let(:mock_custom_background) { double }

      before do
        allow(MiniMagick::Image).to receive(:open).with(background_url).and_return(mock_custom_background)
        allow(mock_custom_background).to receive(:combine_options)
        allow(mock_custom_background).to receive(:composite).and_return(mock_result_image)
      end

      it "uses the custom background URL and crops it to exact dimensions" do
        service_with_background.call

        expect(MiniMagick::Image).to have_received(:open).with(background_url)
        expect(mock_custom_background).to have_received(:combine_options)
        expect(mock_source_image).to have_received(:resize).with("300x300")
        expect(mock_custom_background).to have_received(:composite).with(mock_source_image)
      end

      it "does not use the template when background URL is provided" do
        service_with_background.call

        expect(MiniMagick::Image).not_to have_received(:open).with(Images::TEMPLATE_PATH)
      end
    end

    context "when logo png generation fails" do
      before do
        allow(Settings::General).to receive(:set_logo_png).and_raise(StandardError, "Logo png save failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and continues with other operations" do
        service.call

        expect(Rails.logger).to have_received(:error).with("Failed to generate logo png: Logo png save failed")
        expect(Settings::General).to have_received(:set_resized_logo).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_favicon_url).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_main_social_image).with(uploaded_url, subforem_id: subforem.id)
      end
    end

    context "when resized logo generation fails" do
      before do
        allow(Settings::General).to receive(:set_resized_logo).and_raise(StandardError, "Logo save failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and continues with other operations" do
        service.call

        expect(Rails.logger).to have_received(:error).with("Failed to generate resized logo: Logo save failed")
        expect(Settings::General).to have_received(:set_favicon_url).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_main_social_image).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_logo_png).with(uploaded_url, subforem_id: subforem.id)
      end
    end

    context "when favicon generation fails" do
      before do
        allow(Settings::General).to receive(:set_favicon_url).and_raise(StandardError, "Favicon save failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and continues with other operations" do
        service.call

        expect(Rails.logger).to have_received(:error).with("Failed to generate favicon: Favicon save failed")
        expect(Settings::General).to have_received(:set_resized_logo).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_main_social_image).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_logo_png).with(uploaded_url, subforem_id: subforem.id)
      end
    end

    context "when main social image generation fails" do
      before do
        allow(Settings::General).to receive(:set_main_social_image).and_raise(StandardError, "Social image save failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and continues with other operations" do
        service.call

        expect(Rails.logger).to have_received(:error).with("Failed to generate main social image: Social image save failed")
        expect(Settings::General).to have_received(:set_resized_logo).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_favicon_url).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_logo_png).with(uploaded_url, subforem_id: subforem.id)
      end
    end

    context "when image download fails" do
      before do
        allow(MiniMagick::Image).to receive(:open).with(image_url).and_raise(StandardError, "Download failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and continues with other operations" do
        service.call

        expect(Rails.logger).to have_received(:error).with("Failed to generate resized logo: Download failed")
        expect(Rails.logger).to have_received(:error).with("Failed to generate favicon: Download failed")
        expect(Rails.logger).to have_received(:error).with("Failed to generate main social image: Download failed")
        expect(Rails.logger).to have_received(:error).with("Failed to generate logo png: Download failed")
      end
    end

    context "when upload fails" do
      before do
        allow(ArticleImageUploader).to receive(:new).and_raise(StandardError, "Upload failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and continues with other operations" do
        service.call

        expect(Rails.logger).to have_received(:error).with("Failed to generate resized logo: Upload failed")
        expect(Rails.logger).to have_received(:error).with("Failed to generate favicon: Upload failed")
        expect(Rails.logger).to have_received(:error).with("Failed to generate main social image: Upload failed")
        expect(Rails.logger).to have_received(:error).with("Failed to generate logo png: Upload failed")
      end
    end

    context "when subforem does not exist" do
      it "raises an error" do
        expect { described_class.new(999_999, image_url).call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#resize_image" do
    let(:mock_source_image) { double }
    let(:mock_uploader) { double }
    let(:uploaded_url) { "https://cdn.example.com/resized.png" }

    before do
      allow(MiniMagick::Image).to receive(:open).with(image_url).and_return(mock_source_image)
      allow(mock_source_image).to receive(:resize)
      allow(mock_source_image).to receive(:write)
      allow(ArticleImageUploader).to receive(:new).and_return(mock_uploader)
      allow(mock_uploader).to receive(:store!)
      allow(mock_uploader).to receive(:url).and_return(uploaded_url)
      allow(Tempfile).to receive(:new).and_return(double(close: nil, unlink: nil, path: "/tmp/test.png"))
    end

    it "resizes image to specified dimensions" do
      result = service.send(:resize_image, image_url, 150, 200)

      expect(mock_source_image).to have_received(:resize).with("150x200")
      expect(result).to eq(uploaded_url)
    end
  end

  describe "#create_social_image" do
    let(:mock_source_image) { double }
    let(:mock_background_image) { double }
    let(:mock_result_image) { double }
    let(:mock_uploader) { double }
    let(:uploaded_url) { "https://cdn.example.com/social.png" }

    before do
      allow(MiniMagick::Image).to receive(:open).with(image_url).and_return(mock_source_image)
      allow(MiniMagick::Image).to receive(:open).with(Images::TEMPLATE_PATH).and_return(mock_background_image)
      allow(mock_source_image).to receive(:resize)
      allow(mock_background_image).to receive(:composite).and_return(mock_result_image)
      allow(mock_result_image).to receive(:write)
      allow(ArticleImageUploader).to receive(:new).and_return(mock_uploader)
      allow(mock_uploader).to receive(:store!)
      allow(mock_uploader).to receive(:url).and_return(uploaded_url)
      allow(Tempfile).to receive(:new).and_return(double(close: nil, unlink: nil, path: "/tmp/test.png"))
    end

    context "when no background URL is provided" do
      it "uses the existing social template as background" do
        service.send(:create_social_image)

        expect(MiniMagick::Image).to have_received(:open).with(Images::TEMPLATE_PATH)
      end

      it "resizes source image to 300x300" do
        service.send(:create_social_image)

        expect(mock_source_image).to have_received(:resize).with("300x300")
      end

      it "composites the source image onto the background" do
        service.send(:create_social_image)

        expect(mock_background_image).to have_received(:composite).with(mock_source_image)
      end

      it "returns the uploaded URL" do
        result = service.send(:create_social_image)
        expect(result).to eq(uploaded_url)
      end
    end

    context "when background URL is provided" do
      let(:service_with_background) { described_class.new(subforem.id, image_url, background_url) }
      let(:mock_custom_background) { double }

      before do
        allow(MiniMagick::Image).to receive(:open).with(background_url).and_return(mock_custom_background)
        allow(mock_custom_background).to receive(:combine_options)
        allow(mock_custom_background).to receive(:composite).and_return(mock_result_image)
      end

      it "uses the custom background URL and crops it to exact dimensions" do
        service_with_background.send(:create_social_image)

        expect(MiniMagick::Image).to have_received(:open).with(background_url)
        expect(mock_custom_background).to have_received(:combine_options) do |&block|
          # Create a mock command builder to capture the options
          command = double
          allow(command).to receive(:resize)
          allow(command).to receive(:gravity)
          allow(command).to receive(:extent)

          block.call(command)

          # Verify the specific options were called
          expect(command).to have_received(:resize).with("1000x500^")
          expect(command).to have_received(:gravity).with("Center")
          expect(command).to have_received(:extent).with("1000x500")
        end
      end

      it "does not use the template when background URL is provided" do
        service_with_background.send(:create_social_image)

        expect(MiniMagick::Image).not_to have_received(:open).with(Images::TEMPLATE_PATH)
      end
    end
  end

  describe "#upload_image" do
    let(:mock_image) { double }
    let(:mock_uploader) { double }
    let(:uploaded_url) { "https://cdn.example.com/uploaded.png" }
    let(:mock_tempfile) { double }

    before do
      allow(mock_image).to receive(:write)
      allow(ArticleImageUploader).to receive(:new).and_return(mock_uploader)
      allow(mock_uploader).to receive(:store!)
      allow(mock_uploader).to receive(:url).and_return(uploaded_url)
      allow(Tempfile).to receive(:new).and_return(mock_tempfile)
      allow(mock_tempfile).to receive(:close)
      allow(mock_tempfile).to receive(:unlink)
      allow(mock_tempfile).to receive(:path).and_return("/tmp/test.png")
    end

    it "writes image to tempfile and uploads it" do
      result = service.send(:upload_image, mock_image)

      expect(mock_image).to have_received(:write).with("/tmp/test.png")
      expect(ArticleImageUploader).to have_received(:new)
      expect(mock_uploader).to have_received(:store!).with(mock_tempfile)
      expect(result).to eq(uploaded_url)
    end

    it "cleans up the tempfile" do
      service.send(:upload_image, mock_image)

      expect(mock_tempfile).to have_received(:close)
      expect(mock_tempfile).to have_received(:unlink)
    end
  end

  describe "integration with MiniMagick" do
    let(:mock_source_image) { double }
    let(:mock_background_image) { double }
    let(:mock_result_image) { double }
    let(:mock_uploader) { double }
    let(:uploaded_url) { "https://cdn.example.com/integration.png" }

    before do
      # Stub web requests to prevent real HTTP calls
      stub_request(:get, "https://cdn.example.com/integration.png").to_return(status: 200, body: "", headers: {})

      allow(MiniMagick::Image).to receive(:open).with(image_url).and_return(mock_source_image)
      allow(MiniMagick::Image).to receive(:open).with(Images::TEMPLATE_PATH).and_return(mock_background_image)
      allow(mock_source_image).to receive(:resize)
      allow(mock_source_image).to receive(:write)
      allow(mock_background_image).to receive(:composite).and_return(mock_result_image)
      allow(mock_result_image).to receive(:write)
      allow(ArticleImageUploader).to receive(:new).and_return(mock_uploader)
      allow(mock_uploader).to receive(:store!)
      allow(mock_uploader).to receive(:url).and_return(uploaded_url)
      allow(Tempfile).to receive(:new).and_return(double(close: nil, unlink: nil, path: "/tmp/test.png"))
    end

    it "properly chains MiniMagick operations for social image creation" do
      service.call

      # Verify the background creation
      expect(MiniMagick::Image).to have_received(:open).with(Images::TEMPLATE_PATH)

      # Verify the source image resizing
      expect(mock_source_image).to have_received(:resize).with("300x300")

      # Verify the compositing
      expect(mock_background_image).to have_received(:composite).with(mock_source_image)
    end
  end
end
