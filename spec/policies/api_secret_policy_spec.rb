require "rails_helper"

RSpec.describe ApiSecretPolicy do
  subject { described_class.new(user, api_secret) }

  let(:api_secret) { build(:api_secret) }
  let(:valid_attributes) { %i[description] }

  context "when user is not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user owns the secret" do
    let(:user) { api_secret.user }

    it { is_expected.to permit_actions %i[create destroy] }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end

  context "when user does not own the secret" do
    let(:user) { create(:user) }

    it { is_expected.to permit_actions %i[create] }
    it { is_expected.to forbid_actions %i[destroy] }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end
end
