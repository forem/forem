require "rails_helper"

RSpec.describe ProfileFields::Add, type: :service do
  let(:profile) { create(:user).profile }

  context "when successfully adding a new profile field" do
    it "creates a new profile field and adds a store accessor", :aggregate_failures do
      expect(profile.respond_to?(:new_field)).to be false
      expect do
        described_class.call(label: "New Field")
      end.to change(ProfileField, :count).by(1)
      expect(profile.respond_to?(:new_field)).to be true
    end

    it "returns the correct response object", :aggregate_failures do
      add_response = described_class.call(label: "Another New Field")
      expect(add_response.success?).to be true
      expect(add_response.profile_field).to be_an_instance_of(ProfileField)
      expect(add_response.error_message).to be_blank
    end
  end

  context "when profile field creation fails" do
    it "does not create a new profile field or store accessor" do
      expect { described_class.call({}) }.not_to change(ProfileField, :count)
    end

    it "returns the correct response object", :aggregate_failures do
      add_response = described_class.call({})
      expect(add_response.success?).to be false
      expect(add_response.profile_field).to be_an_instance_of(ProfileField)
      expect(add_response.error_message).to eq "Label can't be blank"
    end
  end
end
