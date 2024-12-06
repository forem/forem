require 'twitter/creatable'
require 'twitter/identity'

module Twitter
  class List < Twitter::Identity
    include Twitter::Creatable
    # @return [Integer]
    attr_reader :member_count, :subscriber_count
    # @return [String]
    attr_reader :description, :full_name, :mode, :name, :slug
    object_attr_reader :User, :user
    predicate_attr_reader :following

    # @return [Addressable::URI] The URI to the list members.
    def members_uri
      Addressable::URI.parse("#{uri}/members") if uri?
    end
    memoize :members_uri
    alias members_url members_uri

    # @return [Addressable::URI] The URI to the list subscribers.
    def subscribers_uri
      Addressable::URI.parse("#{uri}/subscribers") if uri?
    end
    memoize :subscribers_uri
    alias subscribers_url subscribers_uri

    # @return [Addressable::URI] The URI to the list.
    def uri
      Addressable::URI.parse("https://twitter.com/#{user.screen_name}/#{slug}") if slug? && user.screen_name?
    end
    memoize :uri
    alias url uri

    def uri?
      !!uri
    end
    memoize :uri?
  end
end
