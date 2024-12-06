require 'twitter/basic_user'

module Twitter
  class SourceUser < Twitter::BasicUser
    predicate_attr_reader :all_replies, :blocking, :can_dm, :followed_by,
                          :marked_spam, :muting, :notifications_enabled,
                          :want_retweets
  end
end
