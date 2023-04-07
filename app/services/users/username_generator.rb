# Generates available username based on
# multiple generators in the following order:
#   * list of supplied usernames
#   * list of supplied usernames with suffix
#   * random generated letters
#
# @todo Extract username validation in separate class
module Users
  class UsernameGenerator
    attr_reader :usernames

    def self.call(...)
      new(...).call
    end

    # @param usernames [Array<String>] a list of usernames
    def initialize(usernames = [], detector: CrossModelSlug, generator: nil)
      @detector = detector
      @generator = generator || method(:random_username)
      @usernames = usernames
    end

    def call
      first_available_from(normalized_usernames) ||
        first_available_from(suffixed_usernames) ||
        first_available_from(random_usernames)
    end

    def normalized_usernames
      @normalized_usernames ||= filtered_usernames.map { |s| s.downcase.gsub(/[^0-9a-z_]/i, "").delete(" ") }
    end

    def filtered_usernames
      @filtered_usernames ||= usernames.select { |s| s.is_a?(String) && s.present? }
    end

    def random_username
      ("a".."z").to_a.sample(12).join
    end

    def random_usernames
      Array.new(3) { @generator.call }
    end

    private

    def first_available_from(list)
      list.detect { |username| !username_exists?(username) }
    end

    def username_exists?(username)
      @detector.exists?(username)
    end

    def suffixed_usernames
      return [] unless filtered_usernames.any?

      normalized_usernames.map { |stem| [stem, rand(100)].join("_") }
    end
  end
end
