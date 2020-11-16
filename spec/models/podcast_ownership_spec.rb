require "rails_helper"

RSpec.describe PodcastOwnership, type: :model do
  let(:podcast_ownership) { create(:podcast_ownership) }

  describe "validations" do
    describe "builtin validations" do
      subject { podcast_ownership }

      it { is_expected.to validate_presence_of(:podcast_id) }
      it { is_expected.to validate_presence_of(:user_id) }
    end
  end
end
