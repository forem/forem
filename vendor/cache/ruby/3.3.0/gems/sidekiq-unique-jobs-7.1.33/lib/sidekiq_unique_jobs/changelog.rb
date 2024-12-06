# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class Changelogs provides access to the changelog entries
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class Changelog < Redis::SortedSet
    #
    # @return [Integer] the number of matches to return by default
    DEFAULT_COUNT = 1_000
    #
    # @return [String] the default pattern to use for matching
    SCAN_PATTERN  = "*"

    def initialize
      super(CHANGELOGS)
    end

    #
    # Adds a new changelog entry
    #
    # @param [String] message a descriptive message about the entry
    # @param [String] digest a unique digest
    # @param [String] job_id a Sidekiq JID
    # @param [String] script the name of the script adding the entry
    #
    # @return [void]
    #
    def add(message:, digest:, job_id:, script:)
      message = dump_json(message: message, digest: digest, job_id: job_id, script: script)
      redis { |conn| conn.zadd(key, now_f, message) }
    end

    #
    # The change log entries
    #
    # @param [String] pattern the pattern to match
    # @param [Integer] count the number of matches to return
    #
    # @return [Array<Hash>] an array of entries
    #
    def entries(pattern: SCAN_PATTERN, count: DEFAULT_COUNT)
      options = {}
      options[:match] = pattern
      options[:count] = count

      redis do |conn|
        conn.zscan_each(key, **options).to_a.map { |entry| load_json(entry[0]) }
      end
    end

    #
    # Paginate the changelog entries
    #
    # @param [Integer] cursor the cursor for this iteration
    # @param [String] pattern "*" the pattern to match
    # @param [Integer] page_size 100 the number of matches to return
    #
    # @return [Array<Integer, Integer, Array<Hash>] the total size, next cursor and changelog entries
    #
    def page(cursor: 0, pattern: "*", page_size: 100)
      redis do |conn|
        total_size, result = conn.multi do |pipeline|
          pipeline.zcard(key)
          pipeline.zscan(key, cursor, match: pattern, count: page_size)
        end

        [
          total_size.to_i,
          result[0].to_i, # next_cursor
          result[1].map { |entry| load_json(entry[0]) }, # entries
        ]
      end
    end
  end
end
