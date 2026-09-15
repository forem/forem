module SegmentedUsers
  # Service for parsing and resolving user identifiers into valid User records.
  # Handles usernames (with or without @), emails, and user IDs.
  # Also supports populating users from an active UserQuery.
  class UserIdentifierParser
    Result = Struct.new(
      :valid_users,
      :unresolved_identifiers,
      :ineligible_users,
      :duplicate_count,
      keyword_init: true,
    ) do
      def valid_user_ids
        valid_users.map(&:id)
      end

      def eligible_user_ids
        (valid_users - ineligible_users).map(&:id)
      end

      def success?
        valid_users.any?
      end
    end

    def self.call(raw_input: nil, user_query: nil)
      new(raw_input: raw_input, user_query: user_query).call
    end

    def initialize(raw_input: nil, user_query: nil)
      @raw_input = raw_input
      @user_query = user_query
    end

    def call
      resolved_users = []
      unresolved = []
      duplicates = 0

      if user_query.present?
        query_users = resolve_from_user_query(user_query)
        resolved_users.concat(query_users)
      end

      if raw_input.present?
        tokens = tokenize_input(raw_input)
        duplicates += (tokens.size - tokens.uniq.size)
        unique_tokens = tokens.uniq

        text_users, text_unresolved = resolve_tokens(unique_tokens)
        resolved_users.concat(text_users)
        unresolved.concat(text_unresolved)
      end

      deduped_users = resolved_users.uniq(&:id)
      ineligible = deduped_users.reject { |u| user_email_eligible?(u) }

      Result.new(
        valid_users: deduped_users,
        unresolved_identifiers: unresolved.uniq,
        ineligible_users: ineligible,
        duplicate_count: duplicates,
      )
    end

    private

    attr_reader :raw_input, :user_query

    def tokenize_input(input)
      if input.is_a?(Array)
        input.map { |item| item.to_s.strip }.compact_blank
      else
        input.to_s
          .split(/[\r\n,;\t]+/)
          .map(&:strip)
          .compact_blank
      end
    end

    def resolve_tokens(tokens)
      categorized = categorize_tokens(tokens)
      users_by_token = build_user_lookup(categorized)

      found_users = []
      unresolved = []

      tokens.each do |token|
        matched_user = match_token_user(token, users_by_token)
        if matched_user
          found_users << matched_user
        else
          unresolved << token
        end
      end

      [found_users, unresolved]
    end

    def categorize_tokens(tokens)
      categorized = { ids: [], emails: [], usernames: [] }
      tokens.each do |token|
        if token.match?(/\A\d+\z/)
          categorized[:ids] << token.to_i
        elsif token.include?("@") && token.include?(".")
          categorized[:emails] << token.downcase
        else
          clean_username = token.sub(/\A@+/, "").downcase
          categorized[:usernames] << clean_username if clean_username.present?
        end
      end
      categorized
    end

    def build_user_lookup(categorized)
      {
        ids: categorized[:ids].any? ? User.where(id: categorized[:ids]).index_by(&:id) : {},
        emails: categorized[:emails].any? ? query_users_by_email(categorized[:emails]) : {},
        usernames: categorized[:usernames].any? ? query_users_by_username(categorized[:usernames]) : {}
      }
    end

    def query_users_by_email(emails)
      User.where("LOWER(email) IN (?)", emails).index_by { |u| u.email.to_s.downcase }
    end

    def query_users_by_username(usernames)
      User.where("LOWER(username) IN (?)", usernames).index_by { |u| u.username.to_s.downcase }
    end

    def match_token_user(token, lookup)
      if token.match?(/\A\d+\z/)
        lookup[:ids][token.to_i]
      elsif token.include?("@") && token.include?(".")
        lookup[:emails][token.downcase]
      else
        lookup[:usernames][token.sub(/\A@+/, "").downcase]
      end
    end

    def resolve_from_user_query(query)
      query = UserQuery.find_by(id: query) unless query.is_a?(UserQuery)
      return [] unless query&.active?

      executor = UserQueryExecutor.new(query)
      user_ids = []
      executor.each_id_batch(batch_size: 1000) do |batch|
        user_ids.concat(batch)
      end

      user_ids.any? ? User.where(id: user_ids).to_a : []
    rescue StandardError => e
      Rails.logger.error("Failed to execute UserQuery #{query&.id} for segment: #{e.message}")
      []
    end

    def user_email_eligible?(user)
      if user.respond_to?(:base_email_eligible)
        user.base_email_eligible?
      else
        !user.has_role?(:suspended) && !user.has_role?(:spam)
      end
    end
  end
end
