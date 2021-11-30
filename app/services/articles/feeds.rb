module Articles
  module Feeds
    # The default number of days old that an article can be for us
    # to consider it in the relevance feed.
    DEFAULT_PUBLISHED_SINCE = 7

    NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS = 18

    # @api private
    #
    # This method helps answer the question: What are the articles
    # that I should consider as new for the given user?  This method
    # provides a date by which to filter out "stale to the user"
    # articles.
    #
    # @note Do we need to continue using this method?  It's part of
    #       the hot story grab experiment that we ran with the
    #       Article::Feeds::LargeForemExperimental, but may not be
    #       relevant.
    #
    # @param user [User]
    # @param published_since [Integer] if someone
    #        hasn't viewed any articles, give them things from the
    #        database seeds.
    #
    # @return [ActiveSupport::TimeWithZone]
    #
    # @note the published_since is something carried
    #       over from the LargeForemExperimental and may not be
    #       relevant given that we have the :daily_factor_decay.
    #       However, this further limitation based on a user's
    #       second most recent page view helps further winnow down
    #       the result set.
    def self.oldest_published_at_to_consider_for(user:, published_since: DEFAULT_PUBLISHED_SINCE)
      time_of_second_latest_page_view = user&.page_views&.second_to_last&.created_at
      return published_since.days.ago unless time_of_second_latest_page_view

      time_of_second_latest_page_view - NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS.hours
    end
  end
end
