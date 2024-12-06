require 'twitter/rest/account_activity'
require 'twitter/rest/direct_messages'
require 'twitter/rest/direct_messages/welcome_messages'
require 'twitter/rest/favorites'
require 'twitter/rest/friends_and_followers'
require 'twitter/rest/help'
require 'twitter/rest/lists'
require 'twitter/rest/oauth'
require 'twitter/rest/places_and_geo'
require 'twitter/rest/saved_searches'
require 'twitter/rest/search'
require 'twitter/rest/premium_search'
require 'twitter/rest/spam_reporting'
require 'twitter/rest/suggested_users'
require 'twitter/rest/timelines'
require 'twitter/rest/trends'
require 'twitter/rest/tweets'
require 'twitter/rest/undocumented'
require 'twitter/rest/users'

module Twitter
  module REST
    # @note All methods have been separated into modules and follow the same grouping used in {http://dev.twitter.com/doc the Twitter API Documentation}.
    # @see https://dev.twitter.com/overview/general/things-every-developer-should-know
    module API
      include Twitter::REST::AccountActivity
      include Twitter::REST::DirectMessages
      include Twitter::REST::DirectMessages::WelcomeMessages
      include Twitter::REST::Favorites
      include Twitter::REST::FriendsAndFollowers
      include Twitter::REST::Help
      include Twitter::REST::Lists
      include Twitter::REST::OAuth
      include Twitter::REST::PlacesAndGeo
      include Twitter::REST::PremiumSearch
      include Twitter::REST::SavedSearches
      include Twitter::REST::Search
      include Twitter::REST::SpamReporting
      include Twitter::REST::SuggestedUsers
      include Twitter::REST::Timelines
      include Twitter::REST::Trends
      include Twitter::REST::Tweets
      include Twitter::REST::Undocumented
      include Twitter::REST::Users
    end
  end
end
