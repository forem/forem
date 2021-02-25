require "rails_helper"

RSpec.describe ApiSecretPolicy, type: :policy do
  subject { described_class.new(user, api_secret) }

  let(:valid_attributes) { %i[description] }

  context "when user is not signed in" do
    let(:user)       { nil }
    let(:api_secret) { build_stubbed(:api_secret) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user owns the secret" do
    let(:user)       { build_stubbed(:user) }
    let(:api_secret) { build_stubbed(:api_secret, user: user) }

    it { is_expected.to permit_actions %i[create destroy] }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end

  context "when user does not own the secret" do
    let(:user)       { build_stubbed(:user) }
    let(:api_secret) { build_stubbed(:api_secret) }

    it { is_expected.to permit_actions %i[create] }
    it { is_expected.to forbid_actions %i[destroy] }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }
  end

  context "when the user is banned" do
    let(:user) { create(:user, :banned) }
    let(:api_secret) { build_stubbed(:api_secret) }

    it { is_expected.to forbid_actions %i[create] }
  end
end
