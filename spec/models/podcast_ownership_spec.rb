require "rails_helper"

RSpec.describe PodcastOwnership, type: :model do
  let(:podcast_episode) { create(:podcast_episode) }

  describe "validations" do
    describe "builtin validations" do
      subject { podcast_episode }

      it { is_expected.to belong_to(:podcast) }
      it { is_expected.to belong_to(:user) }
      it { is_expected.to validate_presence_of(:podcast_id) }
      it { is_expected.to validate_presence_of(:user_id) }
    end
  end
end
