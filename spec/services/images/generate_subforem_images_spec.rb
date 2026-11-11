require "rails_helper"

RSpec.describe Images::GenerateSubforemImages do
  let(:subforem) { create(:subforem) }
  let(:image_url) { "https://example.com/logo.png" }
  let(:background_url) { "https://example.com/background.png" }
  let(:logo_bytes) { Rails.root.join("spec/fixtures/files/800x600.png").binread }
  let(:background_bytes) { Rails.root.join("spec/fixtures/files/800x600.webp").binread }
  let(:service) { described_class.new(subforem.id, image_url) }

  describe ".call" do
    it "creates a new instance and calls it" do
      allow(described_class).to receive(:new).with(subforem.id, image_url, nil).and_return(service)
      allow(service).to receive(:call)

      described_class.call(subforem.id, image_url)

      expect(described_class).to have_received(:new).with(subforem.id, image_url, nil)
      expect(service).to have_received(:call)
    end

    it "creates a new instance with background URL and calls it" do
      allow(described_class).to receive(:new).with(subforem.id, image_url, background_url).and_return(service)
      allow(service).to receive(:call)

      described_class.call(subforem.id, image_url, background_url)

      expect(described_class).to have_received(:new).with(subforem.id, image_url, background_url)
      expect(service).to have_received(:call)
    end
  end

  describe "#call" do
    let(:mock_uploader) { instance_double(ArticleImageUploader, store!: nil, url: uploaded_url) }
    let(:uploaded_url) { "https://cdn.example.com/uploaded_image.png" }

    before do
      stub_request(:get, image_url).to_return(status: 200, body: logo_bytes)
      stub_request(:get, background_url).to_return(status: 200, body: background_bytes)
      stub_request(:get, uploaded_url).to_return(status: 200, body: "")

      allow(ArticleImageUploader).to receive(:new).and_return(mock_uploader)
      allow(Settings::General).to receive(:set_resized_logo)
      allow(Settings::General).to receive(:set_favicon_url)
      allow(Settings::General).to receive(:set_main_social_image)
      allow(Settings::General).to receive(:set_logo_png)
    end

    context "when all operations succeed" do
      it "generates and saves all images without spawning subprocesses and memoizes the HTTP download",
         :aggregate_failures do
        allow(Open3).to receive(:popen3).and_call_original
        allow(ForemNative).to receive(:subforem_resize_png).and_call_original
        allow(ForemNative).to receive(:subforem_social_image_png).and_call_original

        service.call

        expect(Open3).not_to have_received(:popen3)
        expect(WebMock).to have_requested(:get, image_url).once
        expect(ForemNative).to have_received(:subforem_resize_png)
          .with(logo_bytes, 100, 100, font_path: described_class::DEFAULT_FONT_PATH).twice
        expect(ForemNative).to have_received(:subforem_resize_png)
          .with(logo_bytes, 512, 512, font_path: described_class::DEFAULT_FONT_PATH).once
        expect(ForemNative).to have_received(:subforem_social_image_png)
          .with(
            logo_bytes,
            File.binread(described_class::TEMPLATE_PATH),
            custom_background: false,
            font_path: described_class::DEFAULT_FONT_PATH,
          ).once

        expect(Settings::General).to have_received(:set_resized_logo).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_favicon_url).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_main_social_image).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_logo_png).with(uploaded_url, subforem_id: subforem.id)
      end
    end

    context "when background URL is provided" do
      let(:service_with_background) { described_class.new(subforem.id, image_url, background_url) }

      it "uses the custom background URL and crops it to 1000x500 via ForemNative" do
        allow(ForemNative).to receive(:subforem_social_image_png).and_call_original
        allow(File).to receive(:binread).and_call_original

        service_with_background.call

        expect(WebMock).to have_requested(:get, background_url).once
        expect(File).not_to have_received(:binread).with(described_class::TEMPLATE_PATH)
        expect(ForemNative).to have_received(:subforem_social_image_png)
          .with(
            logo_bytes,
            background_bytes,
            custom_background: true,
            font_path: described_class::DEFAULT_FONT_PATH,
          )
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

        expect(Rails.logger).to have_received(:error)
          .with("Failed to generate main social image: Social image save failed")
        expect(Settings::General).to have_received(:set_resized_logo).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_favicon_url).with(uploaded_url, subforem_id: subforem.id)
        expect(Settings::General).to have_received(:set_logo_png).with(uploaded_url, subforem_id: subforem.id)
      end
    end

    context "when image download fails" do
      before do
        allow(service).to receive(:read_image_bytes).with(image_url).and_raise(StandardError, "Download failed")
        allow(service).to receive(:read_image_bytes).with(described_class::TEMPLATE_PATH).and_call_original
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

  describe "end-to-end pixel dimensions" do
    it "produces valid PNGs at exact expected aspect-fitted and cropped dimensions" do
      stored_dimensions = []
      uploader_double = instance_double(ArticleImageUploader, url: "https://cdn.example.com/out.png")
      allow(uploader_double).to receive(:store!) do |tempfile|
        info = ForemNative.image_inspect_file(tempfile.path)
        stored_dimensions << [info[:format], info[:width], info[:height]]
      end
      allow(ArticleImageUploader).to receive(:new).and_return(uploader_double)
      allow(Settings::General).to receive(:set_resized_logo)
      allow(Settings::General).to receive(:set_favicon_url)
      allow(Settings::General).to receive(:set_main_social_image)
      allow(Settings::General).to receive(:set_logo_png)

      stub_request(:get, image_url).to_return(status: 200, body: logo_bytes)
      stub_request(:get, background_url).to_return(status: 200, body: background_bytes)

      described_class.new(subforem.id, image_url, background_url).call

      expect(stored_dimensions).to eq(
        [
          ["png", 100, 75],
          ["png", 100, 75],
          ["png", 1000, 500],
          ["png", 512, 384],
        ],
      )
    end
  end
end
