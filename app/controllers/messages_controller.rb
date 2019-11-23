class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @message = Message.new(message_params)
    @message.user_id = session_current_user_id
    authorize @message

    if @message.valid?
      begin
        message_json = create_pusher_payload(@message)
        Pusher.trigger(@message.chat_channel.pusher_channels, "message-created", message_json)
      rescue Pusher::Error => e
        logger.info "PUSHER ERROR: #{e.message}"
      end
    end

    if @message.save
      render json: { status: "success", message: "Message created" }, status: :created
    else
      render json: {
        status: "error",
        message: {
          chat_channel_id: @message.chat_channel_id,
          message: @message.errors.full_messages,
          type: "error"
        }
      }, status: :unauthorized
    end
  end

  private

  def create_pusher_payload(new_message)
    {
      user_id: new_message.user.id,
      chat_channel_id: new_message.chat_channel.id,
      chat_channel_adjusted_slug: new_message.chat_channel.adjusted_slug(current_user, "sender"),
      username: new_message.user.username,
      profile_image_url: ProfileImage.new(new_message.user).get(90),
      message: new_message.message_html,
      timestamp: Time.current,
      color: new_message.preferred_user_color,
      reception_method: "pushed"
    }.to_json
  end

  def message_params
    params.require(:message).permit(:message_markdown, :user_id, :chat_channel_id)
  end

  def user_not_authorized
    respond_to do |format|
      format.json do
        render json: {
          status: "error",
          message: {
            chat_channel_id: message_params[:chat_channel_id],
            message: "You can not do that because you are banned",
            type: "error"
          }
        }, status: :unauthorized
      end
    end
  end
end
