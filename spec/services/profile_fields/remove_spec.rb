require "rails_helper"

RSpec.describe ProfileFields::Remove, type: :service do
  context "when successfully removing a profile field" do
    it "removes the profile field and store accessor", :aggregate_failures do
      profile_field = create(:profile_field, label: "Removed field")
      Profile.refresh_store_accessors!
      profile = create(:user).profile

      expect(profile.respond_to?(:removed_field)).to be true
      expect do
        described_class.call(profile_field.id)
      end.to change(ProfileField, :count).by(-1)
      expect(profile.respond_to?(:removed_field)).to be false
    end

    it "returns the correct response object", :aggregate_failures do
      profile_field = create(:profile_field, label: "Another Removed field")
      Profile.refresh_store_accessors!

      add_response = described_class.call(profile_field.id)
      expect(add_response.success?).to be true
      expect(add_response.profile_field).to be_an_instance_of(ProfileField)
      expect(add_response.error_message).to be_blank
    end
  end

  context "when profile field removal fails" do
    let(:id) { 428 }

    before do
      profile_field = instance_double("ProfileField", destroy: false, errors_as_sentence: "Something went wrong")
      allow(ProfileField).to receive(:find).with(id).and_return(profile_field)
    end

    it "does not remove a profile field" do
      expect { described_class.call(id) }.not_to change(ProfileField, :count)
    end

    it "returns the correct response object", :aggregate_failures do
      add_response = described_class.call(id)
      expect(add_response.success?).to be false
      expect(add_response.profile_field).to be_present
      expect(add_response.error_message).to eq "Something went wrong"
    end
  end
end
