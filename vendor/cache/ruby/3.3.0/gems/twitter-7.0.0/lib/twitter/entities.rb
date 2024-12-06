require 'memoizable'
require 'twitter/entity/hashtag'
require 'twitter/entity/symbol'
require 'twitter/entity/uri'
require 'twitter/entity/user_mention'
require 'twitter/media_factory'

module Twitter
  module Entities
    include Memoizable

    # @return [Boolean]
    def entities?
      !@attrs[:entities].nil? && @attrs[:entities].any? { |_, array| array.any? }
    end
    memoize :entities?

    # @note Must include entities in your request for this method to work
    # @return [Array<Twitter::Entity::Hashtag>]
    def hashtags
      entities(Entity::Hashtag, :hashtags)
    end
    memoize :hashtags

    # @return [Boolean]
    def hashtags?
      hashtags.any?
    end
    memoize :hashtags?

    # @note Must include entities in your request for this method to work
    # @return [Array<Twitter::Media>]
    def media
      extended_entities = entities(MediaFactory, :media, :extended_entities)
      extended_entities.empty? ? entities(MediaFactory, :media) : extended_entities
    end
    memoize :media

    # @return [Boolean]
    def media?
      media.any?
    end
    memoize :media?

    # @note Must include entities in your request for this method to work
    # @return [Array<Twitter::Entity::Symbol>]
    def symbols
      entities(Entity::Symbol, :symbols)
    end
    memoize :symbols

    # @return [Boolean]
    def symbols?
      symbols.any?
    end
    memoize :symbols?

    # @note Must include entities in your request for this method to work
    # @return [Array<Twitter::Entity::URI>]
    def uris
      entities(Entity::URI, :urls)
    end
    memoize :uris
    alias urls uris

    # @return [Boolean]
    def uris?
      uris.any?
    end
    alias urls? uris?

    # @note Must include entities in your request for this method to work
    # @return [Array<Twitter::Entity::UserMention>]
    def user_mentions
      entities(Entity::UserMention, :user_mentions)
    end
    memoize :user_mentions

    # @return [Boolean]
    def user_mentions?
      user_mentions.any?
    end
    memoize :user_mentions?

  private

    # @param klass [Class]
    # @param key2 [Symbol]
    # @param key1 [Symbol]
    def entities(klass, key2, key1 = :entities)
      @attrs.fetch(key1.to_sym, {}).fetch(key2.to_sym, []).collect do |entity|
        klass.new(entity)
      end
    end
  end
end
