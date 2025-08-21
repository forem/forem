require "rails_helper"

RSpec.describe PollOption do
  let(:article) { build(:article, featured: true) }
  let(:poll) { build(:poll, article: article) }
  let(:poll_option) { build(:poll_option, poll: poll) }

  describe "validations" do
    describe "builtin validations" do
      subject { poll_option }

      it { is_expected.to belong_to(:poll) }
      it { is_expected.to have_many(:poll_votes).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:markdown) }
      it { is_expected.to validate_presence_of(:poll_votes_count) }
    end

    it "allows up to 256 markdown characters" do
      poll_option.markdown = "0" * 256
      expect(poll_option).to be_valid
    end

    it "disallows over 256 markdown characters" do
      poll_option.markdown = "0" * 257
      expect(poll_option).not_to be_valid
    end
  end
end
