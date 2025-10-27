class UserQuery < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  has_many :emails, dependent: :nullify

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :query, presence: true, length: { maximum: 10_000 }
  validates :max_execution_time_ms, presence: true, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 300_000 # 5 minutes max
  }

  validate :variable_definitions_must_be_valid_json
  validate :variables_must_be_valid_json

  validate :query_must_be_safe
  validate :query_must_return_users
  validate :query_must_be_read_only

  scope :active, -> { where(active: true) }
  scope :recently_executed, -> { where.not(last_executed_at: nil).order(last_executed_at: :desc) }

  # Maximum number of users that can be returned by a query
  MAX_USER_LIMIT = 100_000

  # Allowed SQL keywords and functions for user queries
  ALLOWED_KEYWORDS = %w[
    SELECT FROM WHERE AND OR NOT IN EXISTS BETWEEN IS NULL IS NOT NULL
    ORDER BY LIMIT OFFSET GROUP BY HAVING DISTINCT
    COUNT SUM AVG MIN MAX
    UPPER LOWER TRIM COALESCE CASE WHEN THEN ELSE END
    EXTRACT DATE_TRUNC NOW CURRENT_TIMESTAMP
    JOIN INNER JOIN LEFT JOIN RIGHT JOIN
  ].freeze

  # Dangerous SQL keywords that are not allowed
  FORBIDDEN_KEYWORDS = %w[
    INSERT UPDATE DELETE DROP CREATE ALTER TRUNCATE
    GRANT REVOKE EXECUTE CALL PROCEDURE FUNCTION
    UNION ALL SUBSTRING CONCAT REPLACE
    LOAD_FILE INTO OUTFILE INFILE
    BULK COPY
  ].freeze

  def execute_safely(limit: nil, variables: {})
    return [] unless active?

    # Validate query before execution
    validate_query_safety!

    # Substitute variables if provided
    final_query = substitute_variables(variables)

    # Set up execution environment
    # Use read-only database if available, otherwise fall back to main database
    ReadOnlyDatabaseService.with_connection do |conn|
      # Set statement timeout
      conn.execute("SET statement_timeout = #{max_execution_time_ms}")

      # Create a safe query with user limit
      safe_query = build_safe_query(final_query, limit)

      begin
        # Execute the query with timeout protection
        result = conn.execute(safe_query)

        # Extract user IDs from the result
        user_ids = result.map { |row| row["id"] }.compact.map(&:to_i)

        # Update execution tracking (this still uses the main database)
        update!(
          last_executed_at: Time.current,
          execution_count: execution_count + 1,
        )

        # Return User objects for the found IDs (this still uses the main database)
        User.where(id: user_ids)
      rescue PG::QueryCanceled => e
        Rails.logger.error("UserQuery execution timeout: #{name} - #{e.message}")
        raise QueryTimeoutError, "Query execution exceeded maximum time limit of #{max_execution_time_ms}ms"
      rescue StandardError => e
        Rails.logger.error("UserQuery execution error: #{name} - #{e.message}")
        raise QueryExecutionError, "Query execution failed: #{e.message}"
      end
    end
  end

  def estimated_user_count
    return 0 unless active?

    # Use EXPLAIN to get estimated row count without executing the full query
    explain_query = "EXPLAIN (FORMAT JSON) #{build_safe_query(nil, 1000)}"

    begin
      # Use read-only database if available for EXPLAIN queries
      ReadOnlyDatabaseService.with_connection do |conn|
        result = conn.execute(explain_query)
        plan = result.first["QUERY PLAN"].first

        # Extract estimated rows from the query plan
        if plan["Plan"] && plan["Plan"]["Plan Rows"]
          plan["Plan"]["Plan Rows"].to_i
        else
          0
        end
      end
    rescue StandardError => e
      Rails.logger.warn("Could not estimate user count for query #{name}: #{e.message}")
      0
    end
  end

  def test_execution(limit: 10, variables: {})
    execute_safely(limit: limit, variables: variables)
  end

  def substitute_variables(variables = {})
    return query if variable_definitions.blank? || variables.blank?

    substitutor = UserQueryVariableSubstitutor.new(self, variables)
    substitutor.substituted_query
  end

  def required_variables
    return {} if variable_definitions.blank?

    begin
      JSON.parse(variable_definitions)
    rescue JSON::ParserError
      {}
    end
  end

  def has_variables?
    variable_definitions.present?
  end

  private

  def query_must_be_safe
    return if query.blank?

    query_upper = query.upcase

    # Check for forbidden keywords (more precise matching)
    FORBIDDEN_KEYWORDS.each do |keyword|
      # Use word boundaries to avoid false positives
      pattern = /\b#{Regexp.escape(keyword)}\b/i
      if query_upper.match?(pattern)
        errors.add(:query, "contains forbidden keyword: #{keyword}")
        return
      end
    end

    # Must start with SELECT
    unless query_upper.strip.start_with?("SELECT")
      errors.add(:query, "must start with SELECT")
      return
    end

    # Must select from users table or join with users
    unless query_upper.include?("USERS") || query_upper.include?("FROM users")
      errors.add(:query, "must target the users table")
      return
    end

    # Check for suspicious patterns
    suspicious_patterns = [
      /;\s*\w+/i, # Multiple statements
      /--/,       # SQL comments
      %r{/\*.*\*/}, # Block comments
      /xp_/i,     # Extended procedures
      /sp_/i,     # Stored procedures
      /@@/i,      # System variables
      /exec\s*\(/i, # Dynamic execution
      /eval\s*\(/i, # Eval functions
    ]

    suspicious_patterns.each do |pattern|
      if query.match?(pattern)
        errors.add(:query, "contains suspicious pattern: #{pattern}")
        return
      end
    end
  end

  def query_must_return_users
    return if query.blank?

    # Basic check that query selects user ID
    return if query.upcase.include?("ID") || query.upcase.include?("users.id")

    errors.add(:query, "must select user ID (id or users.id)")
  end

  def query_must_be_read_only
    return if query.blank?

    # Check that query doesn't modify data
    modifying_keywords = %w[INSERT UPDATE DELETE DROP CREATE ALTER TRUNCATE]
    query_upper = query.upcase

    modifying_keywords.each do |keyword|
      # Use word boundaries to avoid false positives
      pattern = /\b#{Regexp.escape(keyword)}\b/i
      if query_upper.match?(pattern)
        errors.add(:query, "cannot modify data - read-only queries only")
        return
      end
    end
  end

  def validate_query_safety!
    # Re-validate the query before execution
    return if valid?

    raise QueryValidationError, "Query validation failed: #{errors.full_messages.join(', ')}"
  end

  def build_safe_query(base_query = nil, limit = nil)
    # Use provided query or default to stored query
    query_with_limit = (base_query || query).strip

    # Ensure query ends with semicolon
    query_with_limit += ";" unless query_with_limit.end_with?(";")

    # Add LIMIT if specified
    if limit
      # Remove any existing LIMIT clause and add our limit
      query_with_limit = query_with_limit.gsub(/\s+LIMIT\s+\d+;?$/i, "")
      query_with_limit = query_with_limit.chomp(";") + " LIMIT #{[limit, MAX_USER_LIMIT].min};"
    end

    query_with_limit
  end

  def variable_definitions_must_be_valid_json
    return if variable_definitions.blank?

    begin
      parsed = JSON.parse(variable_definitions)
      unless parsed.is_a?(Hash)
        errors.add(:variable_definitions, "must be a valid JSON object")
      end
    rescue JSON::ParserError => e
      errors.add(:variable_definitions, "must be valid JSON: #{e.message}")
    end
  end

  def variables_must_be_valid_json
    return if variables.blank?

    begin
      JSON.parse(variables)
    rescue JSON::ParserError => e
      errors.add(:variables, "must be valid JSON: #{e.message}")
    end
  end

  # Custom error classes
  class QueryValidationError < StandardError; end
  class QueryExecutionError < StandardError; end
  class QueryTimeoutError < StandardError; end
end
