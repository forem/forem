module ChatChannels
  class UpdateChannel
    attr_accessor :chat_channel, :params

    def initialize(chat_channel, params)
      @chat_channel = chat_channel
      @params = params
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      chat_channel.update(params)
      chat_channel
    end
  end
end
