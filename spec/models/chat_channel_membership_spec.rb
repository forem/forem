require "rails_helper"

RSpec.describe ChatChannelMembership, type: :model do
  let(:chat_channel) { create(:chat_channel) }
  let(:chat_channel_membership) { create(:chat_channel_membership, chat_channel: chat_channel) }

  describe "validations" do
    describe "builtin validations" do
      subject { chat_channel_membership }

      it { is_expected.to belong_to(:chat_channel) }
      it { is_expected.to belong_to(:user) }

      it { is_expected.to validate_inclusion_of(:role).in_array(%w[member mod]) }

      # rubocop:disable RSpec/NamedSubject
      it {
        expect(subject).to validate_inclusion_of(:status)
          .in_array(%w[active inactive pending rejected left_channel removed_from_channel joining_request])
      }
      # rubocop:enable RSpec/NamedSubject

      it { is_expected.to validate_presence_of(:chat_channel_id) }
      it { is_expected.to validate_presence_of(:user_id) }
      it { is_expected.to validate_uniqueness_of(:chat_channel_id).scoped_to(:user_id) }
    end
  end

  describe "#channel_text" do
    it "sets channel text using name, slug, and human names" do
      chat_channel = chat_channel_membership.chat_channel
      parsed_channel_name = chat_channel_membership.channel_name&.gsub("chat between", "")&.gsub("and", "")
      expected_text = "#{parsed_channel_name} #{chat_channel.slug} #{chat_channel.channel_human_names.join(' ')}"
      expect(chat_channel_membership.channel_text).to eq(expected_text)
    end
  end
end
