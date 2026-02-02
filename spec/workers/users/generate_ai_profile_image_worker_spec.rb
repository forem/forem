require "rails_helper"

RSpec.describe Users::GenerateAiProfileImageWorker, type: :worker do
  subject(:worker) { described_class.new }

  describe "#perform" do
    let(:user_id) { 123 }
    let(:generator) { instance_double(Ai::ImageGenerator) }

    before do
      RequestStore.clear!
      allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions).with(no_args).and_return(nil)
    end

    context "when user cannot be found" do
      it "does not attempt to generate an image" do
        allow(User).to receive(:find_by).with(id: user_id).and_return(nil)

        expect(Ai::ImageGenerator).not_to receive(:new)

        worker.perform(user_id)
      end
    end

    context "when image generation succeeds" do
      let(:user) { instance_double(User, id: user_id) }
      let(:result) do
        Ai::ImageGenerator::GenerationResult.new(url: "https://example.com/sloth.png", text_response: nil)
      end

      before do
        allow(User).to receive(:find_by).with(id: user_id).and_return(user)
        allow(Ai::ImageGenerator).to receive(:new).and_return(generator)
        allow(generator).to receive(:generate).and_return(result)
        allow(user).to receive(:remote_profile_image_url=)
        allow(user).to receive(:save!)
      end

      it "sets the remote profile image and saves the user" do
        worker.perform(user_id)

        expect(Ai::ImageGenerator).to have_received(:new)
          .with("#{described_class::MAGIC_LINK_PLACEHOLDER_PROMPT}.\n\n#{described_class::CONTENT_SAFETY_SUFFIX}")
        expect(user).to have_received(:remote_profile_image_url=).with(result.url)
        expect(user).to have_received(:save!)
      end

      it "includes aesthetic instructions when available" do
        instructions = "Hand-drawn, pastel gradients"
        prompt_with_instructions =
          "#{described_class::MAGIC_LINK_PLACEHOLDER_PROMPT} Style to use if not otherwise contradicted previously: " \
          "#{instructions}.\n\n#{described_class::CONTENT_SAFETY_SUFFIX}"

        allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions).with(no_args).and_return(instructions)

        worker.perform(user_id)

        expect(Ai::ImageGenerator).to have_received(:new).with(prompt_with_instructions)
      end

      it "falls back to default subforem aesthetic instructions" do
        default_subforem_id = 99
        RequestStore.store[:default_subforem_id] = default_subforem_id
        allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions).with(no_args).and_return(nil)
        allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions)
          .with(subforem_id: default_subforem_id)
          .and_return("Vibrant coding-inspired patterns")

        worker.perform(user_id)

        expect(Ai::ImageGenerator).to have_received(:new).with(include("Vibrant coding-inspired patterns"))
      end
    end

    context "when image generation does not return a url" do
      let(:user) { instance_double(User, id: user_id) }

      before do
        allow(User).to receive(:find_by).with(id: user_id).and_return(user)
        allow(Ai::ImageGenerator).to receive(:new).and_return(generator)
        allow(generator).to receive(:generate).and_return(nil)
      end

      it "does not attempt to update the profile image" do
        expect(user).not_to receive(:remote_profile_image_url=)
        expect(user).not_to receive(:save!)

        worker.perform(user_id)
      end
    end
  end
end

