module ChatChannels
  class FindOrCreate
    def initialize(channel_type, slug, contrived_name)
      @channel_type = channel_type
      @slug = slug
      @contrived_name = contrived_name
    end

    def self.call(...)
      new(...).call
    end

    def call
      channel = ChatChannel.find_by(slug: slug)
      if channel
        raise "Blocked channel" if channel.status == "blocked"

        channel.update(status: "active")
      else
        channel = ChatChannel.create(
          channel_type: channel_type,
          channel_name: contrived_name,
          slug: slug,
          last_message_at: 1.week.ago,
          status: "active",
        )
      end
      channel
    end

    private

    attr_reader :channel_type, :slug, :contrived_name
  end
end
