require "rails_helper"

RSpec.describe AssignTagModerator do
  let(:user_one) { create(:user) }
  let(:user_two) { create(:user) }
  let(:tag_one) { create(:tag) }
  let(:tag_two) { create(:tag) }

  before do
    user_ids = [user_one.id, user_two.id]
    tag_ids = [tag_one.id, tag_two.id]
    ChatChannel.create(slug: "tag-moderators", channel_name: "Tag Moderators", channel_type: "invite_only")
    described_class.add_tag_moderators(user_ids, tag_ids)
  end

  it "assigns the correct moderators and tags" do
    expect(tag_two.tag_moderator_ids.count).to eq(1)
  end

  it "adds user to tag moderator channel" do
    channel = ChatChannel.find_by(slug: "tag-moderators")
    expect(channel.users.count).to eq(2)
  end
end
