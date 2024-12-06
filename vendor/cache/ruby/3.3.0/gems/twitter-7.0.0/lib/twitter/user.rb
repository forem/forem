require 'addressable/uri'
require 'twitter/basic_user'
require 'twitter/creatable'
require 'twitter/entity/uri'
require 'twitter/profile'

module Twitter
  class User < Twitter::BasicUser
    include Twitter::Creatable
    include Twitter::Profile
    # @return [Array]
    attr_reader :connections
    # @return [Integer]
    attr_reader :favourites_count, :followers_count, :friends_count,
                :listed_count, :statuses_count, :utc_offset
    # @return [String]
    attr_reader :description, :email, :lang, :location, :name,
                :profile_background_color, :profile_link_color,
                :profile_sidebar_border_color, :profile_sidebar_fill_color,
                :profile_text_color, :time_zone
    alias favorites_count favourites_count
    alias tweets_count statuses_count
    object_attr_reader :Tweet, :status, :user
    alias tweet status
    alias tweet? status?
    alias tweeted? status?
    predicate_attr_reader :contributors_enabled, :default_profile,
                          :default_profile_image, :follow_request_sent,
                          :geo_enabled, :muting, :needs_phone_verification,
                          :notifications, :protected, :profile_background_tile,
                          :profile_use_background_image, :suspended, :verified
    define_predicate_method :translator, :is_translator
    define_predicate_method :translation_enabled, :is_translation_enabled
    uri_attr_reader :profile_background_image_uri, :profile_background_image_uri_https

    class << self
    private

      # Dynamically define a method for entity URIs
      #
      # @param key1 [Symbol]
      # @param key2 [Symbol]
      def define_entity_uris_methods(key1, key2)
        array = key1.to_s.split('_')
        index = array.index('uris')
        array[index] = 'urls'
        url_key = array.join('_').to_sym
        define_entity_uris_method(key1, key2)
        alias_method(url_key, key1)
        define_entity_uris_predicate_method(key1)
        alias_method(:"#{url_key}?", :"#{key1}?")
      end

      def define_entity_uris_method(key1, key2)
        define_method(key1) do
          @attrs.fetch(:entities, {}).fetch(key2, {}).fetch(:urls, []).collect do |url|
            Entity::URI.new(url)
          end
        end
        memoize(key1)
      end

      def define_entity_uris_predicate_method(key1)
        define_method(:"#{key1}?") do
          send(:"#{key1}").any?
        end
        memoize(:"#{key1}?")
      end
    end

    define_entity_uris_methods :description_uris, :description
    define_entity_uris_methods :website_uris, :url

    # @return [Boolean]
    def entities?
      !@attrs[:entities].nil? && @attrs[:entities].any? { |_, hash| hash[:urls].any? }
    end
    memoize :entities?

    # @return [Addressable::URI] The URL to the user.
    def uri
      Addressable::URI.parse("https://twitter.com/#{screen_name}") if screen_name?
    end
    memoize :uri
    alias url uri

    # @return [Addressable::URI] The URL to the user's website.
    def website
      if website_uris?
        website_uris.first.expanded_url
      else
        Addressable::URI.parse(@attrs[:url])
      end
    end
    memoize :website

    def website?
      !!(website_uris? || @attrs[:url])
    end
    memoize :website?
  end
end
