require "rails_helper"

RSpec.describe "Api::V0::ChatChannels", type: :request do
  let(:chat_channel) { create(:chat_channel) }

  describe "GET /api/chat_channels/:id" do
    let(:user) { create(:user) }

    context "when there is no user signed in" do
      before do
        chat_channel.add_users([user])
      end

      it "returns not found" do
        get api_chat_channel_path(chat_channel.id)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current user is a member of the channel" do
      before do
        chat_channel.add_users([user])

        sign_in user
      end

      it "returns ok if user is a member of the channel" do
        get api_chat_channel_path(chat_channel.id)

        expect(response).to have_http_status(:ok)
      end

      it "returns not found if channel id does not exist" do
        get api_chat_channel_path("foobar")

        expect(response).to have_http_status(:not_found)
      end

      it "returns chat channel with the correct json representation", :aggregate_failures do
        get api_chat_channel_path(chat_channel.id)

        response_channel = response.parsed_body
        expected_keys = %w[
          type_of id description channel_name username channel_users channel_mod_ids pending_users_select_fields
        ]
        expect(response_channel.keys).to match_array(expected_keys)

        %w[id description channel_name channel_mod_ids].each do |attr|
          expect(response_channel[attr]).to eq(chat_channel.public_send(attr))
        end

        expect(response_channel["username"]).to eq(chat_channel.channel_name)
        expect(response_channel["pending_users_select_fields"]).to be_empty
      end

      it "returns the correct channel users representation" do
        get api_chat_channel_path(chat_channel.id)

        response_channel = response.parsed_body
        response_channel_users = response_channel["channel_users"]

        membership = user.chat_channel_memberships.last
        expected_last_opened_at = Time.zone.parse(response_channel_users[user.username]["last_opened_at"]).to_i
        response_user = response_channel_users[user.username]

        expect(response_user["profile_image"]).to eq(ProfileImage.new(user).get(width: 90))
        expect(response_user["darker_color"]).to eq(user.decorate.darker_color)
        expect(response_user["name"]).to eq(user.name)
        expect(expected_last_opened_at).to eq(membership.last_opened_at.to_i)
        expect(response_user["username"]).to eq(user.username)
        expect(response_user["id"]).to eq(user.id)
      end

      it "returns the correct pending users select fields representation" do
        # add another user's pending membership
        pending_user = create(:user)
        chat_channel.add_users(pending_user)
        pending_user.chat_channel_memberships.last.update(status: :pending)

        get api_chat_channel_path(chat_channel.id)

        response_channel = response.parsed_body
        response_pending_user_select_fields = response_channel["pending_users_select_fields"].first

        expected_updated_at = Time.zone.parse(response_pending_user_select_fields["updated_at"]).to_i

        expect(response_pending_user_select_fields["id"]).to eq(pending_user.id)
        expect(response_pending_user_select_fields["name"]).to eq(pending_user.name)
        expect(expected_updated_at).to eq(pending_user.updated_at.to_i)
        expect(response_pending_user_select_fields["username"]).to eq(pending_user.username)
      end
    end

    context "when the current user is not a member of the channel" do
      before do
        sign_in user
      end

      it "returns not found if user is not a member" do
        get api_chat_channel_path(chat_channel.id)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
