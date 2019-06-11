require "rails_helper"

RSpec.describe Podcast, type: :model do
  it { is_expected.to validate_presence_of(:image) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:main_color_hex) }
  it { is_expected.to validate_presence_of(:feed_url) }

  describe "validations" do
    let(:podcast) { create(:podcast) }

    it "is valid" do
      expect(podcast).to be_valid
    end

    # Couldn't use shoulda uniqueness matchers for these tests because:
    # Shoulda uses `save(validate: false)` which skips validations
    # So an invalid record is trying to be saved but fails because of the db constraints
    # https://git.io/fjg2g

    it "validates slug uniqueness" do
      podcast2 = build(:podcast, slug: podcast.slug)

      expect(podcast2).not_to be_valid
      expect(podcast2.errors[:slug]).to be_present
    end

    it "validates feed_url uniqueness" do
      podcast2 = build(:podcast, feed_url: podcast.feed_url)

      expect(podcast2).not_to be_valid
      expect(podcast2.errors[:feed_url]).to be_present
    end
  end
end
