require "rails_helper"

RSpec.describe Trends::GenerateCoverImageWorker, type: :worker do
  subject(:worker) { described_class.new }

  describe "#perform" do
    let(:trend) { create(:trend, name: "Ruby 3.4", description: "Awesome new parser changes", cover_image: nil) }
    let(:image_generator) { instance_double(Ai::ImageGenerator) }
    let(:generation_result) { Ai::ImageGenerator::GenerationResult.new(url: "https://example.com/image.png") }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GEMINI_API_KEY").and_return("dummy_api_key")
      allow(Ai::ImageGenerator).to receive(:new).and_return(image_generator)
      allow(image_generator).to receive(:generate).and_return(generation_result)
    end

    context "when GEMINI_API_KEY is not present" do
      before do
        allow(ENV).to receive(:[]).with("GEMINI_API_KEY").and_return(nil)
      end

      it "does not generate cover image" do
        worker.perform(trend.id)
        expect(Ai::ImageGenerator).not_to have_received(:new)
      end
    end

    context "when trend does not exist" do
      it "does not raise error" do
        expect { worker.perform(-1) }.not_to raise_error
      end
    end

    context "when cover_image is already present" do
      before do
        trend.update!(cover_image: "https://example.com/existing.png")
      end

      it "does not generate cover image" do
        worker.perform(trend.id)
        expect(Ai::ImageGenerator).not_to have_received(:new)
      end
    end

    context "when generating image successfully" do
      it "calls ImageGenerator with prompt and correct aspect ratio, and updates trend" do
        expect {
          worker.perform(trend.id)
        }.to change { trend.reload.cover_image }.from(nil).to("https://example.com/image.png")

        expect(Ai::ImageGenerator).to have_received(:new).with(
          a_string_including("Ruby 3.4"),
          aspect_ratio: "16:9"
        )
      end
    end

    context "when image generator returns no result" do
      before do
        allow(image_generator).to receive(:generate).and_return(nil)
      end

      it "does not update trend cover image" do
        expect {
          worker.perform(trend.id)
        }.not_to change { trend.reload.cover_image }
      end
    end

    context "when an error occurs" do
      before do
        allow(image_generator).to receive(:generate).and_raise(StandardError.new("API Error"))
      end

      it "rescues and logs the error" do
        expect(Rails.logger).to receive(:error).with(/AI cover image generation failed for trend/)
        worker.perform(trend.id)
      end
    end
  end
end
