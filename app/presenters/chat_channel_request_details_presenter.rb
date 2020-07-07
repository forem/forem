class ChatChannelRequestDetailsPresenter
  def initialize(chat_channel, current_membership)
    @chat_channel = chat_channel
    @current_membership = current_membership
  end

  attr_accessor :chat_channel, :current_membership

  def as_json
    {

    }
  end
end
