require "rails_helper"

RSpec.describe ResponseTemplatePolicy, type: :policy do
  subject(:response_template_policy) { described_class.new(user, response_template) }

  def valid_attributes
    ResponseTemplatePolicy::PERMITTED_ATTRIBUTES
  end

  context "when user is not signed in" do
    let(:user) { nil }
    let(:response_template) { build_stubbed(:response_template, type_of: "personal_comment", user: nil) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the author" do
    let(:user) { create(:user) }
    let(:second_user) { build_stubbed(:user) }
    let(:response_template) { build_stubbed(:response_template, type_of: "personal_comment", user: second_user) }

    it "permits create and mass assignment while forbidding modification and moderator/admin actions",
       :aggregate_failures do
      expect(response_template_policy).to permit_actions(%i[create])
      expect(response_template_policy).to forbid_actions(
        %i[update destroy admin_index moderator_index moderator_create],
      )
      expect(response_template_policy).to permit_mass_assignment_of(valid_attributes).for_action(:create)
      expect(response_template_policy).to permit_mass_assignment_of(valid_attributes).for_action(:update)
    end
  end

  context "when user is the author" do
    let(:user) { create(:user) }
    let(:response_template) { build_stubbed(:response_template, type_of: "personal_comment", user: user) }

    it "permits create, update, destroy, and mass assignment while forbidding moderator/admin actions",
       :aggregate_failures do
      expect(response_template_policy).to permit_actions(%i[create update destroy])
      expect(response_template_policy).to forbid_actions(%i[admin_index moderator_index moderator_create])
      expect(response_template_policy).to permit_mass_assignment_of(valid_attributes).for_action(:create)
      expect(response_template_policy).to permit_mass_assignment_of(valid_attributes).for_action(:update)
    end
  end

  context "when user is a tag moderator" do
    let(:user) { create(:user, :tag_moderator) }
    let(:response_template) { build_stubbed(:response_template, type_of: "mod_comment", user: nil) }

    it "permits moderator actions while forbidding admin_index, update, and destroy", :aggregate_failures do
      expect(response_template_policy).to permit_actions(%i[moderator_index create moderator_create])
      expect(response_template_policy).to forbid_actions(%i[admin_index update destroy])
    end
  end

  context "when user is an admin" do
    let(:user) { create(:user, :admin) }
    let(:response_template) { build_stubbed(:response_template, type_of: "mod_comment", user: nil) }

    it { is_expected.to permit_actions(%i[moderator_index create moderator_create admin_index update destroy]) }
  end

  context "when user is an super_moderator" do
    let(:user) { create(:user, :super_moderator) }
    let(:response_template) { build_stubbed(:response_template, type_of: "mod_comment", user: nil) }

    it { is_expected.to permit_actions(%i[moderator_index create moderator_create update destroy]) }
  end

  context "when user is trusted" do
    let(:user) { create(:user, :trusted) }
    let(:response_template) { build_stubbed(:response_template, type_of: "mod_comment", user: nil) }

    it "permits moderator_index and moderator_create while forbidding admin_create, update, and destroy",
       :aggregate_failures do
      expect(response_template_policy).to permit_actions(%i[moderator_index moderator_create])
      expect(response_template_policy).to forbid_actions(%i[admin_create update destroy])
    end
  end
end
