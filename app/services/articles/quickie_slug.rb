module Articles
  # Builds short, readable slugs for Quickies (`type_of: "status"` articles).
  #
  # A Quickie's title is its whole post text (up to 256 characters), so slugging the full
  # title produces needlessly long URLs. Instead we keep only the first few meaningful words
  # and append a short random suffix, re-rolling the suffix if the author already has a post
  # with the same slug (slugs are unique per user).
  #
  # Only used when a slug is generated, so slugs that already exist are never changed.
  class QuickieSlug
    MAX_WORDS = 5
    MAX_LENGTH = 40
    MAX_ATTEMPTS = 5
    FALLBACK = "quickie".freeze
    URL_REGEX = %r{https?://\S+}
    FORMATTING_CHARACTERS = /[*_~`#\[\]()]/
    STOP_WORDS = Set.new(%w[
                           a an and are as at be but by for from has have i if in is it its my of on or so
                           that the this to was we with you
                         ]).freeze

    # @param title [String] the Quickie text
    # @param user_id [Integer] the author, since slugs are unique per user
    # @return [String] a slug such as `just-shipped-new-dashboard-redesign-1a2b`
    def self.call(title, user_id:)
      new(title, user_id: user_id).call
    end

    # @see .call
    def initialize(title, user_id:)
      @title = title.to_s
      @user_id = user_id
    end

    # Appends a random suffix to the readable part, re-rolling it if the author already has it.
    def call
      base = base_slug
      MAX_ATTEMPTS.times do
        candidate = "#{base}-#{rand(100_000).to_s(26)}"
        return candidate unless taken?(candidate)
      end
      "#{base}-#{SecureRandom.hex(4)}"
    end

    private

    attr_reader :title, :user_id

    # The readable part: at most MAX_WORDS keywords, trimmed to fit MAX_LENGTH.
    def base_slug
      words = keywords.first(MAX_WORDS)
      # Drop trailing words until the slug fits; a single oversized word is cut instead.
      words.pop while words.size > 1 && words.join("-").length > MAX_LENGTH
      words.join("-")[0, MAX_LENGTH].presence || FALLBACK
    end

    # Lowercased words of the title without URLs, formatting characters or (when possible) stop words.
    def keywords
      text = title.gsub(URL_REGEX, " ").gsub(FORMATTING_CHARACTERS, " ")
      words = Sterile.sluggerize(text).split("-").compact_blank
      meaningful = words.reject { |word| STOP_WORDS.include?(word) }
      meaningful.presence || words
    end

    # Whether this author already has a post with the slug.
    def taken?(slug)
      return false if user_id.blank?

      Article.exists?(user_id: user_id, slug: slug)
    end
  end
end
