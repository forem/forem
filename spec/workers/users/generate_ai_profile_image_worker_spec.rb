require "rails_helper"

RSpec.describe Users::GenerateAiProfileImageWorker, type: :worker do
  subject(:worker) { described_class.new }

  describe "#perform" do
    let(:user_id) { 123 }

    context "when user cannot be found" do
      it "does not attempt to generate an image" do
        allow(User).to receive(:find_by).with(id: user_id).and_return(nil)
        allow(Images::ProfileImageGenerator).to receive(:call)

        worker.perform(user_id)

        expect(Images::ProfileImageGenerator).not_to have_received(:call)
      end
    end

    context "when image generation succeeds" do
      let(:user) { instance_double(User, id: user_id) }
      let(:generated_file) { Rails.root.join("app/assets/images/1.png").open }

      before do
        allow(User).to receive(:find_by).with(id: user_id).and_return(user)
        allow(Images::ProfileImageGenerator).to receive(:call).with(seed: user_id).and_return(generated_file)
        allow(user).to receive(:profile_image=)
        allow(user).to receive(:save!)
      end

      after do
        generated_file.close unless generated_file.closed?
      end

      it "sets the algorithmic profile image and saves the user" do
        worker.perform(user_id)

        expect(Images::ProfileImageGenerator).to have_received(:call).with(seed: user_id)
        expect(user).to have_received(:profile_image=).with(generated_file)
        expect(user).to have_received(:save!)
      end
    end

    context "when image generation returns nil" do
      let(:user) { instance_double(User, id: user_id) }

      before do
        allow(User).to receive(:find_by).with(id: user_id).and_return(user)
        allow(Images::ProfileImageGenerator).to receive(:call).with(seed: user_id).and_return(nil)
        allow(user).to receive(:profile_image=)
        allow(user).to receive(:save!)
      end

      it "does not attempt to update the profile image" do
        worker.perform(user_id)

        expect(user).not_to have_received(:profile_image=)
        expect(user).not_to have_received(:save!)
      end
    end
  end
end
