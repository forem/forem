class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @message = Message.new(message_params)
    success = false

    if @message.save
      begin
        message_json = create_pusher_payload(@message)
        Pusher.trigger(@message.chat_channel.id, "message-created", message_json)
        success = true
      rescue Pusher::Error => e
        logger.info "PUSHER ERROR: #{e.message}"
      end

      if success
        render json: ["Message created"], status: 201
      else
        result = "Message created but could not trigger Pusher"
        render json: [result, @message.to_json], status: 201
      end
    else
      render json: e.message, status: 401
    end
  end

  private

  def create_pusher_payload(new_message)
    {
      username: new_message.user.username,
      message: new_message.message_markdown,
      timestamp: new_message.timestamp,
      color: new_message.user.bg_color_hex,
    }.to_json
  end

  def message_params
    params.require(:message).permit(:message_html, :user_id, :chat_channel_id)
  end
end
