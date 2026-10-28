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

    # Computes every User-to-User check missing from +prefetched+ in one follows query (instead of a
    # find plus a COUNT per check), caches the results, and returns them merged into +prefetched+.
    # Checks whose followable id is not in +existing_user_ids+ are skipped so .call still raises for them.
    def self.fill_user_misses(checks, prefetched, existing_user_ids)
      existing_user_ids = existing_user_ids.to_set
      misses = checks.filter_map do |follower, followable_type, followable_id|
        next unless follower && followable_type == "User" && follower.id != followable_id
        next unless existing_user_ids.include?(followable_id)

        key = new(follower, followable_type, followable_id).cache_key
        [key, [follower.id, followable_id]] unless prefetched.key?(key)
      end.uniq
      return prefetched if misses.empty?

      followed_pairs = Follow.unblocked.where(follower_type: "User", followable_type: "User")
        .where(%i[follower_id followable_id] => misses.map(&:last))
        .pluck(:follower_id, :followable_id).to_set
      results = misses.to_h { |key, pair| [key, followed_pairs.include?(pair)] }
      Rails.cache.write_multi(results, expires_in: CACHE_EXPIRY)
      prefetched.merge(results)
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
