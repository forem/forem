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
      results = misses.to_h.transform_values { |pair| followed_pairs.include?(pair) }
      Rails.cache.write_multi(results, expires_in: CACHE_EXPIRY)
      prefetched.merge(results)
    end

    # Computes every non-User follow check missing from +prefetched+ in one target-id check and one
    # follows query (instead of a find plus a COUNT per id), caches the results, and returns them
    # merged into +prefetched+. Nonexistent followable ids are skipped so .call still raises for them.
    def self.fill_followable_misses(follower, followable_type, followable_ids, prefetched)
      return prefetched unless follower

      misses = followable_ids.uniq.each_with_object({}) do |id, acc|
        key = new(follower, followable_type, id).cache_key
        acc[key] = id unless prefetched.key?(key)
      end
      return prefetched if misses.empty?

      klass = followable_klass(followable_type)
      existing_ids = klass.where(id: misses.values).ids.to_set
      misses.select! { |_, id| existing_ids.include?(id) }
      return prefetched if misses.empty?

      followed_ids = Follow.unblocked
        .where(follower_type: "User", follower_id: follower.id,
               followable_type: klass.name, followable_id: misses.values)
        .pluck(:followable_id).to_set
      results = misses.transform_values { |id| followed_ids.include?(id) }
      Rails.cache.write_multi(results, expires_in: CACHE_EXPIRY)
      prefetched.merge(results)
    end

    # Resolves the ActiveRecord model class for the given +followable_type+ string.
    def self.followable_klass(followable_type)
      %w[Tag Organization Podcast Subforem].include?(followable_type) ? followable_type.constantize : User
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

      @cache_key ||=
        "user-#{follower.id}-#{formatted_follower_updated_at}/is_following_#{followable_type}_#{followable_id}"
    end

    private

    attr_accessor :follower, :followable_type, :followable_id

    def formatted_follower_updated_at
      ts = follower.updated_at
      if follower.instance_variable_defined?(:@rfc3339_cache_pair)
        cached_ts, cached_str = follower.instance_variable_get(:@rfc3339_cache_pair)
        return cached_str if cached_ts == ts
      end

      formatted = ts.respond_to?(:rfc3339) ? ts.rfc3339 : ts.to_s
      follower.instance_variable_set(:@rfc3339_cache_pair, [ts, formatted]) unless follower.frozen?
      formatted
    end

    def following?
      # following? only reads the followable's id and class, so skip hydrating the full row
      follower.following?(followable.select(:id).find(followable_id))
    end

    # Returns the target followable model class for this instance's +followable_type+.
    def followable
      self.class.followable_klass(followable_type)
    end
  end
end
