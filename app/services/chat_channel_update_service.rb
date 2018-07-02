class ChatChannelUpdateService
  attr_accessor :chat_channel, :params

  def initialize(chat_channel, params)
    @chat_channel = chat_channel
    @params = params
  end

  def update
    chat_channel.update(params)
  end
end