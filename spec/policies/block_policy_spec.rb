require "rails_helper"

RSpec.describe BlockPolicy, type: :policy do
  subject { described_class.new(user, block) }

  let(:block) { build_stubbed(:block) }

  let(:valid_attributes) do
    %i[input_html input_css input_javascript featured index_position publish_now]
  end

  context "when not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when signed in as a regular user" do
    let(:user) { build_stubbed(:user) }

    it { is_expected.to forbid_actions(%i[index show new edit create update destroy]) }
  end

  context "when user is signed in as a super admin" do
    let(:user) { create(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[index show new edit create update destroy]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end
end
