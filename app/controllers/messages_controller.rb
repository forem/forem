class MessagesController < ApplicationController
  before_action :set_message, only: %i[destroy update]
  before_action :authenticate_user!, only: %i[create]

  def create
    @message = Message.new(message_params)
    @message.user_id = session_current_user_id
    @temp_message_id = (0...20).map { ("a".."z").to_a[rand(8)] }.join
    authorize @message

    # sending temp message only to sender
    pusher_message_created(true)
    if @message.save
      pusher_message_created(false)
      notify_users(@message.chat_channel.channel_users_ids, "all")
      notify_users(@mentioned_users_id, "mention")
      render json: { status: "success", message: { temp_id: @temp_message_id, id: @message.id } }, status: :created
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

  def destroy
    authorize @message

    if @message.valid?
      begin
        Pusher.trigger(@message.chat_channel.pusher_channels, "message-deleted", @message.to_json)
      rescue Pusher::Error => e
        logger.info "PUSHER ERROR: #{e.message}"
      end
    end

    if @message.destroy
      render json: { status: "success", message: "Message was deleted" }
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

  def update
    authorize @message

    if @message.update(permitted_attributes(@message).merge(edited_at: Time.zone.now))
      if @message.valid?
        begin
          message_json = create_pusher_payload(@message, "")
          Pusher.trigger(@message.chat_channel.pusher_channels, "message-edited", message_json)
        rescue Pusher::Error => e
          logger.info "PUSHER ERROR: #{e.message}"
        end
      end
      render json: { status: "success", message: "Message was edited" }
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

  def create_pusher_payload(new_message, temp_id)
    payload = {
      temp_id: temp_id,
      id: new_message.id,
      user_id: new_message.user.id,
      chat_channel_id: new_message.chat_channel.id,
      chat_channel_adjusted_slug: new_message.chat_channel.adjusted_slug(current_user, "sender"),
      channel_type: new_message.chat_channel.channel_type,
      username: new_message.user.username,
      profile_image_url: ProfileImage.new(new_message.user).get(width: 90),
      message: new_message.message_html,
      markdown: new_message.message_markdown,
      edited_at: new_message.edited_at,
      timestamp: Time.current,
      color: new_message.preferred_user_color,
      reception_method: "pushed"
    }

    if new_message.chat_channel.group?
      payload[:chat_channel_adjusted_slug] = new_message.chat_channel.adjusted_slug
    end
    payload.to_json
  end

  def message_params
    @mentioned_users_id = params[:message][:mentioned_users_id]
    params.require(:message).permit(:message_markdown, :user_id, :chat_channel_id)
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def user_not_authorized
    respond_to do |format|
      format.json do
        render json: {
          status: "error",
          message: {
            chat_channel_id: message_params[:chat_channel_id],
            message: "You can not do that because you are suspended",
            type: "error"
          }
        }, status: :unauthorized
      end
    end
  end

  def pusher_message_created(is_single)
    return unless @message.valid?

    begin
      message_json = create_pusher_payload(@message, @temp_message_id)
      if is_single
        Pusher.trigger("private-message-notifications-#{@message.user_id}", "message-created", message_json)
      else
        Pusher.trigger(@message.chat_channel.pusher_channels, "message-created", message_json)
      end
    rescue Pusher::Error => e
      logger.info "PUSHER ERROR: #{e.message}"
    end
  end

  def notify_users(user_ids, type)
    return unless user_ids

    user_ids.each do |id|
      message_json = create_pusher_payload(@message, @temp_message_id)
      if type == "mention"
        Pusher.trigger("private-message-notifications-#{id}", "mentioned", message_json)
      else
        Pusher.trigger("private-message-notifications-#{id}", "message-created", message_json)
      end
    end
  end
end
