# Checks if an item has been previously imported for the given user
# Item transformed as Article objects are unique per user, not globally
module Feeds
  class CheckItemPreviouslyImported
    def self.call(item, user)
      new(item, user).call
    end

    def initialize(item, user)
      @item = item
      @user = user
    end

    def call
      title = item.title.strip.gsub('"', '\"')
      feed_source_url = item.url.strip.split("?source=")[0]
      relation = user.articles
      relation.where(title: title).or(relation.where(feed_source_url: feed_source_url)).exists?
    end

    private

    attr_reader :item, :user
  end
end
