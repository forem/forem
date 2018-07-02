class ChatChannelCreationService
  attr_accessor :user, :params

  def initialize(user, params)
    @user = user
    @params = params
  end

  def create
    user.chat_channels.create(channel_type: "invite_only",
      channel_name: params[:channel_name], slug: params[:slug])
  end
end