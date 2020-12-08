require "rails_helper"

RSpec.describe PodcastEpisodeAppearance, type: :model do
  let(:podcast_episode_appearance) { create(:podcast_episode_appearance) }

  describe "validations" do
    subject { podcast_episode_appearance }

    it { is_expected.to belong_to(:user).inverse_of(:podcast_episode_appearances) }
    it { is_expected.to belong_to(:podcast_episode) }

    it { is_expected.to validate_presence_of(:podcast_episode_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:role) }

    it do
      expect(podcast_episode_appearance).to validate_inclusion_of(:role).in_array(%w[host guest])
        .with_message("provided role is not valid")
    end

    it { is_expected.to validate_uniqueness_of(:podcast_episode_id).scoped_to(:user_id) }
  end
end
