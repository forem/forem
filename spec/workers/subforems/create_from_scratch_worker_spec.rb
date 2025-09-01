require "rails_helper"

RSpec.describe Subforems::CreateFromScratchWorker do
  let(:subforem) { create(:subforem) }
  let(:brain_dump) { "A community focused on web development and programming" }
  let(:name) { "WebDev Community" }
  let(:logo_url) { "https://example.com/logo.png" }
  let(:bg_image_url) { "https://example.com/background.jpg" }

  describe "#perform" do
    before do
      allow(Settings::Community).to receive(:set_community_name).and_return(name)
      allow(Images::GenerateSubforemImages).to receive(:call)
      allow(Ai::CommunityCopy).to receive(:new).and_return(double(write!: true))
      allow(Ai::ForemTags).to receive(:new).and_return(double(upsert!: true))
      allow(Ai::AboutPageGenerator).to receive(:new).and_return(double(generate!: true))
      allow(Rails.logger).to receive(:info)
    end

    it "sets up the subforem with all AI services" do
      described_class.new.perform(subforem.id, brain_dump, name, logo_url, bg_image_url, "en")

      expect(Settings::Community).to have_received(:set_community_name).with(name, subforem_id: subforem.id)
      expect(Images::GenerateSubforemImages).to have_received(:call).with(subforem.id, logo_url, bg_image_url)
      expect(Ai::CommunityCopy).to have_received(:new).with(subforem.id, brain_dump, "en")
      expect(Ai::ForemTags).to have_received(:new).with(subforem.id, brain_dump, "en")
      expect(Ai::AboutPageGenerator).to have_received(:new).with(subforem.id, brain_dump, name, "en")
    end

    it "works without background image URL" do
      described_class.new.perform(subforem.id, brain_dump, name, logo_url, nil, "en")

      expect(Images::GenerateSubforemImages).to have_received(:call).with(subforem.id, logo_url, nil)
    end

    it "logs success message" do
      described_class.new.perform(subforem.id, brain_dump, name, logo_url, bg_image_url, "en")

      expect(Rails.logger).to have_received(:info).with("Successfully created subforem #{subforem.domain} with AI services")
    end

    context "when an error occurs" do
      before do
        allow(Settings::Community).to receive(:set_community_name).and_return(name).and_raise(StandardError, "Settings error")
        allow(Rails.logger).to receive(:error)
        allow(Honeybadger).to receive(:notify) if defined?(Honeybadger)
      end

      it "logs error and re-raises" do
        expect do
          described_class.new.perform(subforem.id, brain_dump, name, logo_url, bg_image_url, "en")
        end.to raise_error(StandardError, "Settings error")

        expect(Rails.logger).to have_received(:error).with("Failed to create subforem #{subforem.id} with AI services: Settings error")
        expect(Honeybadger).to have_received(:notify) if defined?(Honeybadger)
      end
    end

    context "when subforem does not exist" do
      it "raises an error" do
        expect do
          described_class.new.perform(999_999, brain_dump, name, logo_url, bg_image_url)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
