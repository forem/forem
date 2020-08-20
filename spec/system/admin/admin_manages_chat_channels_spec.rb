require "rails_helper"

RSpec.describe "Admin manages chat channels", type: :system do
  let(:admin) { create(:user, :super_admin) }

  def clear_search_box
    fill_in "q_channel_name_cont", with: ""
  end

  before do
    sign_in admin
    visit admin_chat_channels_path
  end

  it "loads the view" do
    expect(page).to have_content("Chat Channels")
    expect(page).to have_content("Create New Connect Channel")
    expect(page).to have_content("Group Connect Channels")
  end

  context "when creating a chat channel" do
    it "creates a chat channel" do
      fill_in "chat_channel_channel_name", with: "Cool chat"
      fill_in "chat_channel_usernames_string", with: admin.username.to_s
      click_on "Create Chat channel"

      expect(page.body).to have_link("Cool chat")
    end
  end

  context "when searching for chat channels" do
    let(:chat_channel1) { create(:chat_channel, channel_name: "Interesting chat", channel_type: "invite_only") }
    let(:chat_channel2) { create(:chat_channel, channel_name: "Boring chat", channel_type: "invite_only") }

    before do
      clear_search_box
    end

    it "searches chat channels" do
      fill_in "q_channel_name_cont", with: chat_channel1.channel_name.to_s
      click_on "Search"

      expect(page.body).to have_link(chat_channel1.channel_name)
      expect(page.body).not_to have_link(chat_channel2.channel_name)
    end
  end

  context "when a channel without users exists" do
    let(:chat_channel1) { create(:chat_channel, channel_name: "No users chat", channel_type: "invite_only") }

    it "displays a 'Delete Channel' button" do
      fill_in "chat_channel_channel_name", with: "No users chat"
      click_on "Create Chat channel"

      expect(page).to have_content("No users chat")
      expect(page).to have_content("Delete Channel")
    end
  end
end
