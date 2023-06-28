require "rails_helper"

RSpec.describe ResponseTemplatePolicy, type: :policy do
  subject(:response_template_policy) { described_class.new(user, response_template) }

  def valid_attributes
    ResponseTemplatePolicy::PERMITTED_ATTRIBUTES
  end

  context "when user is not signed in" do
    let(:user) { nil }
    let(:response_template) { create(:response_template, type_of: "personal_comment", user: nil) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the author" do
    let(:user) { create(:user) }
    let(:second_user) { create(:user) }
    let(:response_template) { create(:response_template, type_of: "personal_comment", user: second_user) }

    it { is_expected.to permit_actions(%i[create]) }
    it { is_expected.to forbid_actions(%i[update destroy admin_index moderator_index moderator_create]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes).for_action(:create) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes).for_action(:update) }
  end

  context "when user is the author" do
    let(:user) { create(:user) }
    let(:response_template) { create(:response_template, type_of: "personal_comment", user: user) }

    it { is_expected.to permit_actions(%i[create update destroy]) }
    it { is_expected.to forbid_actions(%i[admin_index moderator_index moderator_create]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes).for_action(:create) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes).for_action(:update) }
  end

  context "when user is a tag moderator" do
    let(:user) { create(:user, :tag_moderator) }
    let(:response_template) { create(:response_template, type_of: "mod_comment", user: nil) }

    it { is_expected.to permit_actions(%i[moderator_index create moderator_create]) }
    it { is_expected.to forbid_actions(%i[admin_index update destroy]) }
  end

  context "when user is an admin" do
    let(:user) { create(:user, :admin) }
    let(:response_template) { create(:response_template, type_of: "mod_comment", user: nil) }

    it { is_expected.to permit_actions(%i[moderator_index create moderator_create admin_index update destroy]) }
  end

  context "when user is an super_moderator" do
    let(:user) { create(:user, :super_moderator) }
    let(:response_template) { create(:response_template, type_of: "mod_comment", user: nil) }

    it { is_expected.to permit_actions(%i[moderator_index create moderator_create update destroy]) }
  end
end
