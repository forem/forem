require "pg_query"

class UserQueryValidator
  include ActiveModel::Validations

  # Maximum query length
  MAX_QUERY_LENGTH = 10_000

  # Maximum number of users that can be returned
  MAX_USER_LIMIT = 100_000

  # Allowed column identifiers for user ID
  ALLOWED_ID_NAMES = %w[id user_id].freeze

  # Allowed SQL keywords for read-only queries
  ALLOWED_KEYWORDS = %w[
    SELECT FROM WHERE AND OR NOT IN EXISTS BETWEEN IS NULL IS NOT NULL
    ORDER BY LIMIT OFFSET GROUP BY HAVING DISTINCT
    COUNT SUM AVG MIN MAX
    UPPER LOWER TRIM COALESCE CASE WHEN THEN ELSE END
    EXTRACT DATE_TRUNC NOW CURRENT_TIMESTAMP
    JOIN INNER JOIN LEFT JOIN RIGHT JOIN
    LIKE ILIKE SIMILAR TO
    ASC DESC
  ].freeze

  # Dangerous SQL keywords that are forbidden
  FORBIDDEN_KEYWORDS = %w[
    INSERT UPDATE DELETE DROP CREATE ALTER TRUNCATE
    GRANT REVOKE EXECUTE CALL PROCEDURE FUNCTION
    UNION ALL UNION SUBSTRING CONCAT REPLACE
    LOAD_FILE INTO OUTFILE INFILE
    BULK COPY
    DECLARE SET EXEC
    BEGIN COMMIT ROLLBACK
    SAVEPOINT RELEASE
    LOCK UNLOCK
    VACUUM ANALYZE REINDEX
  ].freeze

  # Allowed table names for joins
  ALLOWED_TABLES = %w[
    users
    profiles
    users_settings
    users_notification_settings
    articles
    comments
    reactions
    follows
    tags
    organizations
    organization_memberships
    badge_achievements
    notes
    feedback_messages
    identities
    github_repos
    ahoy_events
    ahoy_visits
    ahoy_messages
    segmented_users
    audience_segments
    events
    event_signups
    poll_votes
    page_views
  ].freeze

  # Suspicious patterns that indicate potential SQL injection or dangerous operations
  SUSPICIOUS_PATTERNS = [
    /;\s*\w+/i,                    # Multiple statements
    /--/,                          # SQL comments
    %r{/\*.*\*/},                  # Block comments
    /xp_/i,                        # Extended procedures
    /sp_/i,                        # Stored procedures
    /@@/i,                         # System variables
    /exec\s*\(/i,                  # Dynamic execution
    /eval\s*\(/i,                  # Eval functions
    /char\s*\(/i,                  # Char function (potential for encoding attacks)
    /ascii\s*\(/i,                 # ASCII function
    /hex\s*\(/i,                   # Hex function
    /unhex\s*\(/i,                 # Unhex function
    /benchmark\s*\(/i,             # Benchmark function
    /sleep\s*\(/i,                 # Sleep function
    /waitfor\s+delay/i,            # Waitfor delay
    /pg_sleep\s*\(/i,              # PostgreSQL sleep
    /information_schema/i,         # Information schema access
    /pg_catalog/i,                 # PostgreSQL system catalog
    /mysql\.user/i,                # MySQL system tables
    /sys\./i,                      # System tables
    /\buser\s*\(/i,                # User function (potential for info gathering)
    /\bdatabase\s*\(/i,            # Database function
    /\bversion\s*\(/i,             # Version function
    /\bcurrent_user/i,             # Current user function
    /\bsession_user/i,             # Session user function
    /\bsystem_user/i,              # System user function
    /\bhost_name/i,                # Host name function
    /\bapp_name/i,                 # Application name function
    /\bconnection_id/i,            # Connection ID function
    /\bgetdate\s*\(/i,             # GetDate function
    /\bgetutcdate\s*\(/i,          # GetUTCDate function
    /\bnewid\s*\(/i,               # NewID function
    /\brand\s*\(/i,                # Rand function
    /\bchecksum\s*\(/i,            # Checksum function
    /\bhashbytes\s*\(/i,           # HashBytes function
    /\bconvert\s*\(/i,             # Convert function
    /\bcast\s*\(/i,                # Cast function
    /\bopenquery\s*\(/i,           # OpenQuery function
    /\bopendatasource\s*\(/i,      # OpenDataSource function
    /\bopenrowset\s*\(/i,          # OpenRowset function
  ].freeze

  attr_reader :query, :errors

  def initialize(query)
    @query = query.to_s.strip
    @errors = []
  end

  def valid?
    @errors.clear
    return false unless validate_query_presence
    return false unless validate_query_length
    return false unless validate_parentheses

    validate_starts_with_select
    validate_forbidden_keywords
    validate_suspicious_patterns
    validate_ast
    validate_read_only_operations

    @errors.uniq!
    @errors.empty?
  end

  def validate!
    return true if valid?

    raise UserQuery::QueryValidationError, error_messages.join("; ")
  end

  def error_messages
    @errors
  end

  private

  def validate_query_presence
    return true if @query.present?

    @errors << "Query cannot be blank"
    false
  end

  def validate_query_length
    return true unless @query.length > MAX_QUERY_LENGTH

    @errors << "Query exceeds maximum length of #{MAX_QUERY_LENGTH} characters"
    false
  end

  def validate_parentheses
    return true if balanced_parentheses?

    @errors << "Query contains unbalanced parentheses"
    false
  end

  def validate_starts_with_select
    return true if @query.strip.upcase.start_with?("SELECT")

    @errors << "Query must start with SELECT"
    false
  end

  def validate_forbidden_keywords
    query_upper = @query.upcase

    FORBIDDEN_KEYWORDS.each do |keyword|
      pattern = /\b#{Regexp.escape(keyword)}\b/i
      if query_upper.match?(pattern)
        @errors << "Query contains forbidden keyword: #{keyword}"
      end
    end
  end

  def validate_suspicious_patterns
    SUSPICIOUS_PATTERNS.each do |pattern|
      if @query.match?(pattern)
        @errors << "Query contains suspicious pattern: #{pattern.inspect}"
      end
    end
  end

  def validate_ast
    query_for_parsing = @query.gsub(/\{\{\s*[\w.-]+\s*\}\}/, "'__dummy_var__'")

    begin
      parsed = PgQuery.parse(query_for_parsing)
    rescue PgQuery::ParseError => e
      @errors << "Query syntax error: #{e.message}"
      return
    end

    if parsed.tree.stmts.size != 1
      @errors << "Query must contain only a single statement"
      return
    end

    stmt_node = parsed.tree.stmts.first&.stmt
    if stmt_node.nil? || stmt_node.node != :select_stmt
      @errors << "Query must start with SELECT"
      return
    end

    select_stmt = stmt_node.select_stmt
    validate_select_statement_clauses(select_stmt)
    validate_ast_tables(parsed.tables)
    validate_ast_target_columns(select_stmt)
  end

  def validate_select_statement_clauses(select_stmt)
    if select_stmt.into_clause.present?
      @errors << "Query cannot modify data - read-only queries only"
    end

    if select_stmt.locking_clause.present?
      @errors << "Query cannot use locking clauses (FOR UPDATE/SHARE)"
    end

    return unless select_stmt.op != :SETOP_NONE

    @errors << "Query cannot use set operations (UNION, INTERSECT, EXCEPT)"
  end

  def validate_ast_tables(tables)
    normalized_tables = tables.map(&:downcase)

    unless normalized_tables.include?("users")
      @errors << "Query must target the users table"
    end

    unauthorized_tables = normalized_tables - ALLOWED_TABLES
    return if unauthorized_tables.empty?

    @errors << "Query references unauthorized tables: #{unauthorized_tables.join(', ')}"
  end

  def validate_ast_target_columns(select_stmt)
    return if selects_user_id?(select_stmt)

    @errors << "Query must select user ID (id or users.id)"
  end

  def selects_user_id?(select_stmt)
    return false if select_stmt.target_list.blank?

    select_stmt.target_list.any? do |target|
      res = target.res_target
      next false unless res

      name = res.name.to_s.downcase
      next true if ALLOWED_ID_NAMES.include?(name)

      val = res.val
      if val&.column_ref
        fields = val.column_ref.fields.filter_map { |f| f.string&.sval }
        next true if fields.last.to_s.downcase == "id"
      end

      false
    end
  end

  def validate_read_only_operations
    return if @query.blank?

    query_upper = @query.upcase
    modifying_keywords = %w[INSERT UPDATE DELETE DROP CREATE ALTER TRUNCATE]

    modifying_keywords.each do |keyword|
      pattern = /\b#{Regexp.escape(keyword)}\b/i
      if query_upper.match?(pattern)
        @errors << "Query cannot modify data - read-only queries only"
        break
      end
    end
  end

  def balanced_parentheses?
    count = 0
    @query.each_char do |char|
      case char
      when "("
        count += 1
      when ")"
        count -= 1
        return false if count.negative?
      end
    end
    count.zero?
  end

  def extract_table_names(query_str)
    query_for_parsing = query_str.to_s.gsub(/\{\{\s*[\w.-]+\s*\}\}/, "'__dummy_var__'")
    parsed = PgQuery.parse(query_for_parsing)
    parsed.tables.map(&:downcase).uniq
  rescue StandardError
    # Fallback to regex if parsing fails
    table_names = []
    from_matches = query_str.scan(/\bFROM\s+(\w+)/i)
    table_names.concat(from_matches.flatten.map(&:downcase))
    join_matches = query_str.scan(/\b(?:LEFT|RIGHT|INNER)?\s*JOIN\s+(\w+)/i)
    table_names.concat(join_matches.flatten.map(&:downcase))
    table_names.uniq
  end
end
