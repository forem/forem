module Twitter
  module Streaming
    class Event
      LIST_EVENTS = %i[
        list_created list_destroyed list_updated list_member_added
        list_member_added list_member_removed list_user_subscribed
        list_user_subscribed list_user_unsubscribed list_user_unsubscribed
      ].freeze

      TWEET_EVENTS = %i[
        favorite unfavorite quoted_tweet
      ].freeze

      attr_reader :name, :source, :target, :target_object

      # @param data [Hash]
      def initialize(data)
        @name = data[:event].to_sym
        @source = Twitter::User.new(data[:source])
        @target = Twitter::User.new(data[:target])
        @target_object = target_object_factory(@name, data[:target_object])
      end

    private

      def target_object_factory(event_name, data)
        if LIST_EVENTS.include?(event_name)
          Twitter::List.new(data)
        elsif TWEET_EVENTS.include?(event_name)
          Twitter::Tweet.new(data)
        end
      end
    end
  end
end
