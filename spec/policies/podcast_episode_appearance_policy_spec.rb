require "rails_helper"

RSpec.describe PodcastEpisodeAppearancePolicy, type: :policy do
  subject(:podcast_episode_appearance_policy) { described_class.new(user, podcast_episode_appearance) }

  let(:podcast_episode_appearance) { create(:podcast_episode_appearance, podcast_episode: create(:podcast_episode)) }

  context "when user is not signed-in" do
    let(:user) { nil }
    let(:podcast_episode_appearance) { build_stubbed(:podcast_episode_appearance) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the podcast owner" do
    let(:user) { build_stubbed(:user) }
    let(:podcast_episode_appearance) { build_stubbed(:podcast_episode_appearance) }

    it { is_expected.to forbid_actions(%i[new create edit update destroy]) }
  end

  context "when user is the podcast owner" do
    let(:user) { create(:user) }
    let(:podcast) { create(:podcast) }
    let(:podcast_episode) { create(:podcast_episode, podcast: podcast) }
    let(:podcast_episode_appearance) { create(:podcast_episode_appearance, podcast_episode: podcast_episode) }

    before { create(:podcast_ownership, podcast: podcast, owner: user) }

    it { is_expected.to permit_actions(%i[new create edit update destroy]) }

    context "with banned status" do
      before { user.add_role(:banned) }

      it { is_expected.to forbid_actions(%i[new create edit update destroy]) }
    end
  end
end
