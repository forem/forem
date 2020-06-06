require "rails_helper"

RSpec.describe AssignTagModerator, type: :labor do
  let(:user_one) { create(:user) }
  let(:user_two) { create(:user) }
  let(:mod_relator) { create(:user) }
  let(:tag_one) { create(:tag) }
  let(:tag_two) { create(:tag) }

  before do
    mod_relator.add_role(:mod_relations_admin)
    user_ids = [user_one.id, user_two.id]
    tag_ids = [tag_one.id, tag_two.id]
    ChatChannel.create(slug: "tag-moderators", channel_name: "Tag Moderators", channel_type: "invite_only")
    described_class.add_tag_moderators(user_ids, tag_ids)
  end

  it "assigns the correct moderators and tags" do
    expect(tag_two.tag_moderator_ids.count).to eq(1)
  end

  it "assigns the mod with the tag that lines up in the array" do
    expect(user_one.has_role?(:tag_moderator, tag_one)).to be(true)
    expect(user_two.has_role?(:tag_moderator, tag_two)).to be(true)
  end

  it "adds user to tag moderator channel" do
    channel = ChatChannel.find_by(slug: "tag-moderators")
    expect(channel.users.count).to eq(2)
  end

  it "creates channel and adds user to channel when tag doesn't already have channel" do
    channel = ChatChannel.find_by(channel_name: "##{tag_one.name} mods")
    expect(tag_one.reload.mod_chat_channel_id).to eq(channel.id)
    expect(user_one.chat_channels).to include(channel)
    expect(mod_relator.chat_channels).to include(channel)
  end

  it "adds user to channel when tag already has channel" do
    user_three = create(:user)
    described_class.add_tag_moderators([user_three.id], [tag_one.id])
    channel = ChatChannel.find_by(channel_name: "##{tag_one.name} mods")
    expect(channel.active_users).to include(user_three)
  end
end
