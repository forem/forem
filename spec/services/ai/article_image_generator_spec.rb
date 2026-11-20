require "rails_helper"

RSpec.describe Ai::ArticleImageGenerator, type: :service do
  let(:user) { create(:user) }
  let(:image_generator) do
    instance_double(Ai::ImageGenerator,
                    generate: Ai::ImageGenerator::GenerationResult.new(url: "https://example.com/image.png"),
                    failure_reason: nil)
  end

  before do
    allow(Ai::ImageGenerator).to receive(:new).and_return(image_generator)
  end

  it "returns the generated image url" do
    result = described_class.call(prompt: "A cat", user: user)

    expect(result).to be_success
    expect(result.url).to eq("https://example.com/image.png")
  end

  it "returns the failure reason when generation fails" do
    allow(image_generator).to receive_messages(generate: nil, failure_reason: :transient)

    result = described_class.call(prompt: "A cat", user: user)

    expect(result).not_to be_success
    expect(result).not_to be_refused
    expect(result.failure_reason).to eq(:transient)
  end

  it "flags a refusal so callers can ask the user to rephrase" do
    allow(image_generator).to receive_messages(generate: nil, failure_reason: :refused)

    expect(described_class.call(prompt: "A cat", user: user)).to be_refused
  end

  it "frames the prompt as an explicit image request and appends safety instructions" do
    allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions).and_return(nil)

    described_class.call(prompt: "A cat", user: user)

    expect(Ai::ImageGenerator).to have_received(:new)
      .with("Generate an image of: A cat.\n\n#{described_class::SAFETY_INSTRUCTIONS}",
            aspect_ratio: anything, affected_user: user)
  end

  it "includes the subforem's aesthetic instructions after the request" do
    allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions).and_return("watercolor")

    described_class.call(prompt: "A cat", user: user)

    expect(Ai::ImageGenerator).to have_received(:new)
      .with(a_string_starting_with("Generate an image of: A cat.\n\n" \
                                   "Style to use if not otherwise contradicted by the request: watercolor."),
            aspect_ratio: anything, affected_user: user)
  end

  it "uses an explicit aspect ratio when given" do
    described_class.call(prompt: "A cat", user: user, aspect_ratio: "1:1")

    expect(Ai::ImageGenerator).to have_received(:new).with(anything, aspect_ratio: "1:1", affected_user: user)
  end

  it "defaults to 16:9 in limit mode" do
    allow(Settings::UserExperience).to receive(:cover_image_fit).and_return("limit")

    described_class.call(prompt: "A cat", user: user)

    expect(Ai::ImageGenerator).to have_received(:new).with(anything, aspect_ratio: "16:9", affected_user: user)
  end

  it "derives the aspect ratio from the cover image height in crop mode" do
    allow(Settings::UserExperience).to receive_messages(cover_image_fit: "crop", cover_image_height: 420)

    described_class.call(prompt: "A cat", user: user)

    expect(Ai::ImageGenerator).to have_received(:new).with(anything, aspect_ratio: "21:9", affected_user: user)
  end

  describe ".valid_aspect_ratio?" do
    it "accepts supported ratios and rejects others" do
      expect(described_class.valid_aspect_ratio?("16:9")).to be(true)
      expect(described_class.valid_aspect_ratio?("7:3")).to be(false)
    end
  end
end
