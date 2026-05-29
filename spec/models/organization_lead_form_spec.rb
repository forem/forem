require "rails_helper"

RSpec.describe OrganizationLeadForm do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(150) }
    it { is_expected.to validate_presence_of(:button_text) }
    it { is_expected.to validate_length_of(:button_text).is_at_most(40) }
    it { is_expected.to validate_length_of(:description).is_at_most(500) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to have_many(:lead_submissions).dependent(:destroy) }
  end

  describe "scopes" do
    let(:organization) { create(:organization) }

    it "returns only active forms" do
      active = create(:organization_lead_form, organization: organization, active: true)
      create(:organization_lead_form, organization: organization, active: false)

      expect(described_class.active).to eq([active])
    end
  end
end
