require "rails_helper"

RSpec.describe CannedResponsePolicy, type: :policy do
  subject(:canned_response_policy) { described_class.new(user, canned_response) }

  def valid_attributes
    %i[content title]
  end

  context "when user is not signed in" do
    let(:user) { nil }
    let(:canned_response) { create(:canned_response, type_of: "personal_comment", user: nil) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the author" do
    let(:user) { create(:user) }
    let(:canned_response) { create(:canned_response, type_of: "personal_comment", user_id: user.id + 1) }

    it { is_expected.to permit_actions(%i[create]) }
    it { is_expected.to forbid_actions(%i[update destroy admin_index moderator_index moderator_create]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes).for_action(:create) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes).for_action(:update) }
  end

  context "when user is the author" do
    let(:user) { create(:user) }
    let(:canned_response) { create(:canned_response, type_of: "personal_comment", user: user) }

    it { is_expected.to permit_actions(%i[create update destroy]) }
    it { is_expected.to forbid_actions(%i[admin_index moderator_index moderator_create]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes).for_action(:create) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes).for_action(:update) }
  end

  context "when user is a tag moderator" do
    let(:user) { create(:user, :tag_moderator) }
    let(:canned_response) { create(:canned_response, type_of: "mod_comment", user: nil) }

    it { is_expected.to permit_actions(%i[moderator_index create moderator_create]) }
    it { is_expected.to forbid_actions(%i[update destroy admin_index]) }
  end

  context "when user is an admin" do
    let(:user) { create(:user, :admin) }
    let(:canned_response) { create(:canned_response, type_of: "mod_comment", user: nil) }

    it { is_expected.to permit_actions(%i[moderator_index create moderator_create admin_index]) }
    it { is_expected.to forbid_actions(%i[update destroy]) }
  end
end
