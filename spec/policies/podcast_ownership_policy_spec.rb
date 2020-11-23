require "rails_helper"
RSpec.describe PodcastOwnershipPolicy do
  subject { described_class.new(user, podcast_ownership) }

  context "when user is not signed in" do
    let(:user)       { nil }
    let(:podcast_ownership) { build_stubbed(:podcast_ownership) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user owns the podcast" do
    let(:user)       { build_stubbed(:user) }
    let(:podcast_ownership) { build_stubbed(:podcast_ownership) }

    it { is_expected.to permit_actions %i[update edit destroy] }
  end

  context "when user does not own the podcast" do
    let(:user)       { build_stubbed(:user) }
    let(:podcast_ownership) { build_stubbed(:podcast_ownership) }

    it { is_expected.to permit_actions %i[new create] }
  end
end
