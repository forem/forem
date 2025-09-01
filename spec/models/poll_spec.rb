require "rails_helper"

RSpec.describe Poll, type: :model do
  let(:poll) { create(:poll) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:poll_options_count) }
    it { is_expected.to validate_presence_of(:poll_skips_count) }
    it { is_expected.to validate_presence_of(:poll_votes_count) }
    it { is_expected.to validate_presence_of(:prompt_markdown) }
    it { is_expected.to validate_presence_of(:type_of) }
    it { is_expected.to validate_length_of(:prompt_markdown).is_at_most(500) }
    it { is_expected.to validate_length_of(:poll_options_input_array).is_at_least(2) }
    it { is_expected.to validate_length_of(:poll_options_input_array).is_at_most(15) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:article).optional }
    it { is_expected.to belong_to(:survey).optional }
    it { is_expected.to have_many(:poll_options).dependent(:delete_all) }
    it { is_expected.to have_many(:poll_skips).dependent(:delete_all) }
    it { is_expected.to have_many(:poll_votes).dependent(:delete_all) }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:type_of).with_values(single_choice: 0, multiple_choice: 1, scale: 2,
                                                               text_input: 3)
    }
  end

  describe "callbacks" do
    it "evaluates markdown before save" do
      poll.prompt_markdown = "**Bold text**"
      poll.save!
      expect(poll.prompt_html.strip).to eq("<strong>Bold text</strong>")
    end

    it "creates poll options after create" do
      poll_options_input_array = ["Option 1", "Option 2", "Option 3"]
      poll = build(:poll, poll_options_input_array: poll_options_input_array)
      poll.save!
      expect(poll.poll_options.count).to eq(3)
      expect(poll.poll_options.pluck(:markdown)).to eq(poll_options_input_array)
    end

    it "creates poll options with supplementary text after create" do
      poll_options_input_array = ["Option 1", "Option 2", "Option 3"]
      poll_options_supplementary_text_array = ["Desc 1", "Desc 2", "Desc 3"]
      poll = build(:poll, 
        poll_options_input_array: poll_options_input_array,
        poll_options_supplementary_text_array: poll_options_supplementary_text_array
      )
      poll.save!
      expect(poll.poll_options.count).to eq(3)
      expect(poll.poll_options.pluck(:markdown)).to eq(poll_options_input_array)
      expect(poll.poll_options.pluck(:supplementary_text)).to eq(poll_options_supplementary_text_array)
    end

    it "sets default position for polls in surveys" do
      survey = create(:survey)
      poll1 = create(:poll, survey: survey, position: nil)
      poll2 = create(:poll, survey: survey, position: nil)
      
      # Reload to get the actual positions from the database
      poll1.reload
      poll2.reload
      
      expect(poll1.position).to eq(0)
      expect(poll2.position).to eq(1)
    end
  end

  describe "#vote_previously_recorded_for?" do
    let(:user) { create(:user) }

    context "when user has voted" do
      before do
        poll_option = poll.poll_options.first
        create(:poll_vote, user: user, poll: poll, poll_option: poll_option)
      end

      it "returns true" do
        expect(poll.vote_previously_recorded_for?(user_id: user.id)).to be true
      end
    end

    context "when user has skipped" do
      before do
        create(:poll_skip, user: user, poll: poll)
      end

      it "returns true" do
        expect(poll.vote_previously_recorded_for?(user_id: user.id)).to be true
      end
    end

    context "when user has not voted or skipped" do
      it "returns false" do
        expect(poll.vote_previously_recorded_for?(user_id: user.id)).to be false
      end
    end
  end

  describe "#voting_data" do
    let(:poll_option1) { poll.poll_options.first }
    let(:poll_option2) { poll.poll_options.second }

    before do
      create(:poll_vote, poll: poll, poll_option: poll_option1)
      create(:poll_vote, poll: poll, poll_option: poll_option1)
      create(:poll_vote, poll: poll, poll_option: poll_option2)
      # Update the poll's vote count to match the created votes
      poll.update_column(:poll_votes_count, 3)
    end

    it "returns correct voting data" do
      voting_data = poll.voting_data
      expect(voting_data[:votes_count]).to eq(3)
      expect(voting_data[:votes_distribution]).to include([poll_option1.id, 2])
      expect(voting_data[:votes_distribution]).to include([poll_option2.id, 1])
    end
  end

  describe "poll types" do
    describe "#allows_multiple_votes?" do
      it "returns false for single choice polls" do
        expect(poll.allows_multiple_votes?).to be false
      end

      it "returns true for multiple choice polls" do
        multiple_choice_poll = create(:poll, :multiple_choice)
        expect(multiple_choice_poll.allows_multiple_votes?).to be true
      end

      it "returns true for scale polls" do
        scale_poll = create(:poll, :scale)
        expect(scale_poll.allows_multiple_votes?).to be true
      end

      it "returns true for text input polls" do
        text_input_poll = create(:poll, :text_input)
        expect(text_input_poll.allows_multiple_votes?).to be true
      end
    end

    describe "#scale_poll?" do
      it "returns false for non-scale polls" do
        expect(poll.scale_poll?).to be false
        expect(create(:poll, :multiple_choice).scale_poll?).to be false
        expect(create(:poll, :text_input).scale_poll?).to be false
      end

      it "returns true for scale polls" do
        scale_poll = create(:poll, :scale)
        expect(scale_poll.scale_poll?).to be true
      end
    end

    describe "#text_input_poll?" do
      it "returns false for non-text-input polls" do
        expect(poll.text_input_poll?).to be false
        expect(create(:poll, :multiple_choice).text_input_poll?).to be false
        expect(create(:poll, :scale).text_input_poll?).to be false
      end

      it "returns true for text input polls" do
        text_input_poll = create(:poll, :text_input)
        expect(text_input_poll.text_input_poll?).to be true
      end
    end

    describe "#scale_range" do
      it "returns nil for non-scale polls" do
        expect(poll.scale_range).to be_nil
      end

      it "returns scale range for scale polls" do
        scale_poll = create(:poll, :scale)
        expect(scale_poll.scale_range).to eq([1, 2, 3, 4, 5])
      end
    end
  end

  describe "#move_to_position" do
    let(:survey) { create(:survey) }
    let!(:poll1) { create(:poll, survey: survey, position: 0) }
    let!(:poll2) { create(:poll, survey: survey, position: 1) }
    let!(:poll3) { create(:poll, survey: survey, position: 2) }

    it "moves poll to new position and bumps others" do
      poll1.move_to_position(2)
      
      expect(poll1.reload.position).to eq(2)
      expect(poll2.reload.position).to eq(0)
      expect(poll3.reload.position).to eq(1)
    end

    it "does nothing when moving to same position" do
      original_positions = [poll1.position, poll2.position, poll3.position]
      poll1.move_to_position(0)
      
      expect(poll1.reload.position).to eq(0)
      expect(poll2.reload.position).to eq(1)
      expect(poll3.reload.position).to eq(2)
    end

    it "returns early when poll has no survey" do
      poll_without_survey = create(:poll, survey: nil)
      expect { poll_without_survey.move_to_position(1) }.not_to change { poll_without_survey.reload.position }
    end
  end
end
