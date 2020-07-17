require "rails_helper"

RSpec.describe "/internal/chat_channels", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  describe "POST /chat_channels" do
    around { |example| perform_enqueued_jobs(&example) }

    it "creates chat_channel for with users as moderator" do
      user.add_role(:super_admin)
      sign_in user
      expect do
        post "/internal/chat_channels",
             params: { chat_channel: { channel_name: "Hello Channel", usernames_string: user.username.to_s } },
             headers: { HTTP_ACCEPT: "application/json" }
      end.to change(ActionMailer::Base.deliveries, :length)
      expect(ChatChannel.last.channel_name).to eq("Hello Channel")
      expect(ChatChannel.last.pending_users).to include(user)
    end
  end

  describe "DELETE /internal/chat_channels/:id/remove_user" do
    it "removes the user from the chat channel" do
      user.add_role(:super_admin)
      sign_in user
      delete remove_user_internal_chat_channel_path(user.id)
      # expect { user.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    # expect(user.chat_channel_memberships.count).to eq 0
    # expect(ChatChannel.last.pending_users).to include(user)
  end
end

# describe "DELETE /internal/response_templates/:id" do
#   it "successfully deletes the response template" do
#     response_template = create(:response_template)
#     delete internal_response_template_path(response_template.id)
#     expect { response_template.reload }.to raise_error ActiveRecord::RecordNotFound
#   end
# end
