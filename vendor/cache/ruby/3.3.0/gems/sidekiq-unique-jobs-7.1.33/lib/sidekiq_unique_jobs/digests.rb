# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class Changelogs provides access to the changelog entries
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class Digests < Redis::SortedSet
    #
    # @return [Integer] the number of matches to return by default
    DEFAULT_COUNT = 1_000
    #
    # @return [String] the default pattern to use for matching
    SCAN_PATTERN  = "*"

    def initialize(digests_key = DIGESTS)
      super(digests_key)
    end

    #
    # Adds a digest
    #
    # @param [String] digest the digest to add
    #
    def add(digest)
      redis { |conn| conn.zadd(key, now_f, digest) }
    end

    # Deletes unique digests by pattern
    #
    # @param [String] pattern a key pattern to match with
    # @param [Integer] count the maximum number
    # @return [Hash<String,Float>] Hash mapping of digest matching the given pattern and score

    def delete_by_pattern(pattern, count: DEFAULT_COUNT)
      result, elapsed = timed do
        digests = entries(pattern: pattern, count: count).keys
        redis { |conn| BatchDelete.call(digests, conn) }
      end

      log_info("#{__method__}(#{pattern}, count: #{count}) completed in #{elapsed}ms")

      result
    end

    # Delete unique digests by digest
    #   Also deletes the :AVAILABLE, :EXPIRED etc keys
    #
    # @param [String] digest a unique digest to delete
    def delete_by_digest(digest) # rubocop:disable Metrics/MethodLength
      result, elapsed = timed do
        call_script(:delete_by_digest, [
                      digest,
                      "#{digest}:QUEUED",
                      "#{digest}:PRIMED",
                      "#{digest}:LOCKED",
                      "#{digest}:RUN",
                      "#{digest}:RUN:QUEUED",
                      "#{digest}:RUN:PRIMED",
                      "#{digest}:RUN:LOCKED",
                      key,
                    ])
      end

      log_info("#{__method__}(#{digest}) completed in #{elapsed}ms")

      result
    end

    #
    # The entries in this sorted set
    #
    # @param [String] pattern SCAN_PATTERN the match pattern to search for
    # @param [Integer] count DEFAULT_COUNT the number of entries to return
    #
    # @return [Array<String>] an array of digests matching the given pattern
    #
    def entries(pattern: SCAN_PATTERN, count: DEFAULT_COUNT)
      options = {}
      options[:match] = pattern
      options[:count] = count

      redis { |conn| conn.zscan_each(key, **options).to_a }.to_h
    end

    #
    # Returns a paginated
    #
    # @param [Integer] cursor the cursor for this iteration
    # @param [String] pattern SCAN_PATTERN the match pattern to search for
    # @param [Integer] page_size 100 the size per page
    #
    # @return [Array<Integer, Integer, Array<Lock>>] total_size, next_cursor, locks
    #
    def page(cursor: 0, pattern: SCAN_PATTERN, page_size: 100)
      redis do |conn|
        total_size, digests = conn.multi do |pipeline|
          pipeline.zcard(key)
          pipeline.zscan(key, cursor, match: pattern, count: page_size)
        end

        [
          total_size.to_i,
          digests[0].to_i, # next_cursor
          digests[1].map { |digest, score| Lock.new(digest, time: score) }, # entries
        ]
      end
    end
  end
end
