require "rails_helper"

RSpec.describe Ai::ArticleImageGenerator, type: :service do
  let(:user) { create(:user) }
  let(:image_generator) do
    instance_double(Ai::ImageGenerator,
                    generate: Ai::ImageGenerator::GenerationResult.new(url: "https://example.com/image.png"))
  end

  before do
    allow(Ai::ImageGenerator).to receive(:new).and_return(image_generator)
  end

  it "returns the generated image url" do
    expect(described_class.call(prompt: "A cat", user: user)).to eq("https://example.com/image.png")
  end

  it "returns nil when generation fails" do
    allow(image_generator).to receive(:generate).and_return(nil)

    expect(described_class.call(prompt: "A cat", user: user)).to be_nil
  end

  it "appends safety instructions to the prompt" do
    described_class.call(prompt: "A cat", user: user)

    expect(Ai::ImageGenerator).to have_received(:new)
      .with("A cat.\n\n#{described_class::SAFETY_INSTRUCTIONS}", aspect_ratio: anything, affected_user: user)
  end

  it "includes the subforem's aesthetic instructions" do
    allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions).and_return("watercolor")

    described_class.call(prompt: "A cat", user: user)

    expect(Ai::ImageGenerator).to have_received(:new)
      .with(a_string_including("A cat. Style to use if not otherwise contradicted previously: watercolor."),
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
