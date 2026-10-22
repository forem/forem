module Follows
  class CheckCached
    CACHE_EXPIRY = 20.hours

    def self.call(follower, followable_type, followable_id, prefetched = nil)
      new(follower, followable_type, followable_id).call(prefetched)
    end

    # Reads the cached results for many [follower, followable_type, followable_id] checks in a
    # single cache round-trip. Pass the returned hash to .call so misses are computed and written
    # without a second cache read.
    def self.read_multi(checks)
      keys = checks.filter_map { |args| new(*args).cache_key }.uniq
      return {} if keys.empty?

      Rails.cache.read_multi(*keys)
    end

    def initialize(follower, followable_type, followable_id)
      @follower = follower
      @followable_type = followable_type
      @followable_id = followable_id
    end

    def call(prefetched = nil)
      return false unless follower

      key = cache_key
      return Rails.cache.fetch(key, expires_in: CACHE_EXPIRY) { following? } unless prefetched
      return prefetched[key] if prefetched.key?(key)

      following?.tap { |result| Rails.cache.write(key, result, expires_in: CACHE_EXPIRY) }
    end

    def cache_key
      return unless follower

      formatted_updated_at = follower.updated_at.respond_to?(:rfc3339) ? follower.updated_at.rfc3339 : follower.updated_at.to_s
      "user-#{follower.id}-#{formatted_updated_at}/is_following_#{followable_type}_#{followable_id}"
    end

    private

    attr_accessor :follower, :followable_type, :followable_id

    def following?
      # following? only reads the followable's id and class, so skip hydrating the full row
      follower.following?(followable.select(:id).find(followable_id))
    end

    def followable
      case followable_type
      when "Tag", "Organization", "Podcast", "Subforem"
        followable_type.constantize
      else
        User
      end
    end
  end
end
