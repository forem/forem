require "rails_helper"

RSpec.describe PodcastAppearance, type: :model do
  let(:podcast_appearance) { create(:podcast_appearance) }

  describe "validations" do
    subject { podcast_appearance }

    it do
      expect(podcast_appearance).to belong_to(:user).class_name("User").with_foreign_key(:user_id)
        .inverse_of(:podcast_appearances)
    end

    it { is_expected.to belong_to(:podcast_episode) }

    it { is_expected.to validate_presence_of(:podcast_episode_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_uniqueness_of(:podcast_episode_id).scoped_to(:user_id) }
  end
end
