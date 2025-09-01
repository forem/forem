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

    it "allows up to 500 supplementary text characters" do
      poll_option.supplementary_text = "0" * 500
      expect(poll_option).to be_valid
    end

    it "disallows over 500 supplementary text characters" do
      poll_option.supplementary_text = "0" * 501
      expect(poll_option).not_to be_valid
    end
  end

  describe "#move_to_position" do
    let(:poll) { create(:poll) }
    let!(:option1) { create(:poll_option, poll: poll, position: 0) }
    let!(:option2) { create(:poll_option, poll: poll, position: 1) }
    let!(:option3) { create(:poll_option, poll: poll, position: 2) }

    it "moves option to new position and bumps others" do
      option1.move_to_position(2)
      
      expect(option1.reload.position).to eq(2)
      expect(option2.reload.position).to eq(0)
      expect(option3.reload.position).to eq(1)
    end

    it "does nothing when moving to same position" do
      option1.move_to_position(0)
      
      expect(option1.reload.position).to eq(0)
      expect(option2.reload.position).to eq(1)
      expect(option3.reload.position).to eq(2)
    end
  end
end
