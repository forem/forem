require "rails_helper"

RSpec.describe Users::PrefillMlhProfileWorker, type: :worker do
  let(:worker) { subject }
  let(:user) { create(:user) }
  let(:mapped) { { "location" => "Brooklyn, NY, US" } }

  before do
    omniauth_mock_mlh_payload
    create(:identity, user: user, provider: "mlh", token: "mlh-access-token")
    allow(Mlh::UserProfile).to receive(:call).and_return(mapped)
  end

  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    it "fills in fields from MLH data" do
      worker.perform(user.id)

      expect(user.profile.reload.location).to eq("Brooklyn, NY, US")
    end

    it "fetches with the token stored on the identity" do
      worker.perform(user.id)

      expect(Mlh::UserProfile).to have_received(:call).with("mlh-access-token")
    end

    it "does not overwrite a field that already has a value" do
      user.profile.update!(location: "Somewhere else")

      worker.perform(user.id)

      expect(user.profile.reload.location).to eq("Somewhere else")
    end

    context "with a configured profile field" do
      let(:mapped) { super().merge("education" => "Acadia University") }

      before do
        group = create(:profile_field_group, name: "Basic")
        create(:profile_field, label: "Education", profile_field_group: group).update!(attribute_name: "education")
        Profile.refresh_attributes!
      end

      after { Profile.refresh_attributes! }

      it "sets the profile field value" do
        worker.perform(user.id)

        expect(user.profile.reload.education).to eq("Acadia University")
      end

      it "does not overwrite a field that already has a value" do
        user.profile.update!(education: "Existing school")

        worker.perform(user.id)

        expect(user.profile.reload.education).to eq("Existing school")
      end
    end

    it "does nothing when the user is gone" do
      expect { worker.perform(User.maximum(:id).to_i + 1) }.not_to raise_error
    end

    it "does nothing without an MLH identity" do
      other_user = create(:user)

      other_user.identities.destroy_all
      worker.perform(other_user.id)

      expect(Mlh::UserProfile).not_to have_received(:call)
    end

    it "makes no changes when MLH returns no fields" do
      allow(Mlh::UserProfile).to receive(:call).and_return({})

      expect { worker.perform(user.id) }.not_to change { user.profile.reload.location }
    end

    it "swallows a terminal ClientError so Sidekiq does not retry" do
      allow(Mlh::UserProfile).to receive(:call).and_raise(Mlh::ApiClient::ClientError)

      expect { worker.perform(user.id) }.not_to raise_error
      expect(user.profile.reload.location).to be_blank
    end

    it "lets a RecoverableError propagate so Sidekiq retries" do
      allow(Mlh::UserProfile).to receive(:call).and_raise(Mlh::ApiClient::RecoverableError)

      expect { worker.perform(user.id) }.to raise_error(Mlh::ApiClient::RecoverableError)
    end
  end
end
