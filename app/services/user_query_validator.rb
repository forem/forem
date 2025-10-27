class UserQueryValidator
  include ActiveModel::Validations

  # Maximum query length
  MAX_QUERY_LENGTH = 10_000

  # Maximum number of users that can be returned
  MAX_USER_LIMIT = 100_000

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
    UNION ALL SUBSTRING CONCAT REPLACE
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
    /\bxp_cmdshell/i,              # Extended procedure
    /\bxp_regread/i,               # Extended procedure
    /\bxp_regwrite/i,              # Extended procedure
    /\bxp_enumgroups/i,            # Extended procedure
    /\bxp_loginconfig/i,           # Extended procedure
    /\bxp_ntsec_enumdomains/i,     # Extended procedure
    /\bxp_ntsec_enumusers/i,       # Extended procedure
    /\bxp_terminate_process/i,     # Extended procedure
    /\bxp_fileexist/i,             # Extended procedure
    /\bxp_getfiledetails/i,        # Extended procedure
    /\bxp_getnetname/i,            # Extended procedure
    /\bxp_regdeletevalue/i,        # Extended procedure
    /\bxp_regenumvalues/i,         # Extended procedure
    /\bxp_regaddmultistring/i,     # Extended procedure
    /\bxp_regremovemultistring/i,  # Extended procedure
    /\bxp_regdeletekey/i,          # Extended procedure
    /\bxp_enumerrorlogs/i,         # Extended procedure
    /\bxp_readerrorlog/i,          # Extended procedure
    /\bxp_findnextmsg/i,           # Extended procedure
    /\bxp_instance_regread/i,      # Extended procedure
    /\bxp_instance_regwrite/i,     # Extended procedure
    /\bxp_instance_regdeletevalue/i, # Extended procedure
    /\bxp_instance_regenumvalues/i,  # Extended procedure
    /\bxp_instance_regaddmultistring/i, # Extended procedure
    /\bxp_instance_regremovemultistring/i, # Extended procedure
    /\bxp_instance_regdeletekey/i, # Extended procedure
    /\bxp_mkdir/i,                 # Extended procedure
    /\bxp_subdirs/i,               # Extended procedure
    /\bxp_dirtree/i,               # Extended procedure
    /\bxp_availablemedia/i,        # Extended procedure
    /\bxp_fixeddrives/i,           # Extended procedure
    /\bxp_logininfo/i,             # Extended procedure
    /\bxp_grantlogin/i,            # Extended procedure
    /\bxp_revokelogin/i,           # Extended procedure
    /\bxp_enumsid/i,               # Extended procedure
    /\bxp_logevent/i,              # Extended procedure
    /\bxp_msver/i,                 # Extended procedure
    /\bxp_sprintf/i,               # Extended procedure
    /\bxp_sscanf/i,                # Extended procedure
    /\bxp_sqlinventory/i,          # Extended procedure
    /\bxp_sqltrace/i,              # Extended procedure
    /\bxp_sqlagent_enum_jobs/i,    # Extended procedure
    /\bxp_sqlagent_enum_jobs/i,    # Extended procedure
    /\bxp_sqlagent_is_starting/i,  # Extended procedure
    /\bxp_sqlagent_notify/i,       # Extended procedure
    /\bxp_sqlagent_start_job/i,    # Extended procedure
    /\bxp_sqlagent_stop_job/i,     # Extended procedure
    /\bxp_sqlmaint/i,              # Extended procedure
    /\bxp_sqltrace/i,              # Extended procedure
    /\bxp_enum_oledb_providers/i,  # Extended procedure
    /\bxp_enumdsn/i,               # Extended procedure
    /\bxp_enumgroups/i,            # Extended procedure
    /\bxp_loginconfig/i,           # Extended procedure
    /\bxp_ntsec_enumdomains/i,     # Extended procedure
    /\bxp_ntsec_enumusers/i,       # Extended procedure
    /\bxp_terminate_process/i,     # Extended procedure
    /\bxp_fileexist/i,             # Extended procedure
    /\bxp_getfiledetails/i,        # Extended procedure
    /\bxp_getnetname/i,            # Extended procedure
    /\bxp_regdeletevalue/i,        # Extended procedure
    /\bxp_regenumvalues/i,         # Extended procedure
    /\bxp_regaddmultistring/i,     # Extended procedure
    /\bxp_regremovemultistring/i,  # Extended procedure
    /\bxp_regdeletekey/i,          # Extended procedure
    /\bxp_enumerrorlogs/i,         # Extended procedure
    /\bxp_readerrorlog/i,          # Extended procedure
    /\bxp_findnextmsg/i,           # Extended procedure
    /\bxp_instance_regread/i,      # Extended procedure
    /\bxp_instance_regwrite/i,     # Extended procedure
    /\bxp_instance_regdeletevalue/i, # Extended procedure
    /\bxp_instance_regenumvalues/i,  # Extended procedure
    /\bxp_instance_regaddmultistring/i, # Extended procedure
    /\bxp_instance_regremovemultistring/i, # Extended procedure
    /\bxp_instance_regdeletekey/i, # Extended procedure
    /\bxp_mkdir/i,                 # Extended procedure
    /\bxp_subdirs/i,               # Extended procedure
    /\bxp_dirtree/i,               # Extended procedure
    /\bxp_availablemedia/i,        # Extended procedure
    /\bxp_fixeddrives/i,           # Extended procedure
    /\bxp_logininfo/i,             # Extended procedure
    /\bxp_grantlogin/i,            # Extended procedure
    /\bxp_revokelogin/i,           # Extended procedure
    /\bxp_enumsid/i,               # Extended procedure
    /\bxp_logevent/i,              # Extended procedure
    /\bxp_msver/i,                 # Extended procedure
    /\bxp_sprintf/i,               # Extended procedure
    /\bxp_sscanf/i,                # Extended procedure
    /\bxp_sqlinventory/i,          # Extended procedure
    /\bxp_sqltrace/i,              # Extended procedure
    /\bxp_sqlagent_enum_jobs/i,    # Extended procedure
    /\bxp_sqlagent_enum_jobs/i,    # Extended procedure
    /\bxp_sqlagent_is_starting/i,  # Extended procedure
    /\bxp_sqlagent_notify/i,       # Extended procedure
    /\bxp_sqlagent_start_job/i,    # Extended procedure
    /\bxp_sqlagent_stop_job/i,     # Extended procedure
    /\bxp_sqlmaint/i,              # Extended procedure
    /\bxp_sqltrace/i,              # Extended procedure
    /\bxp_enum_oledb_providers/i,  # Extended procedure
    /\bxp_enumdsn/i,               # Extended procedure
  ].freeze

  attr_reader :query, :errors

  def initialize(query)
    @query = query.to_s.strip
    @errors = []
  end

  def valid?
    @errors.clear
    validate_query_presence
    validate_query_length
    validate_query_structure
    validate_forbidden_keywords
    validate_suspicious_patterns
    validate_table_access
    validate_read_only_operations
    @errors.empty?
  end

  def error_messages
    @errors
  end

  private

  def validate_query_presence
    return if @query.present?

    @errors << "Query cannot be blank"
  end

  def validate_query_length
    return unless @query.length > MAX_QUERY_LENGTH

    @errors << "Query exceeds maximum length of #{MAX_QUERY_LENGTH} characters"
  end

  def validate_query_structure
    return if @query.blank?

    query_upper = @query.upcase

    # Must start with SELECT
    unless query_upper.start_with?("SELECT")
      @errors << "Query must start with SELECT"
    end

    # Must select from users table or join with users
    unless query_upper.include?("USERS") || query_upper.include?("FROM users")
      @errors << "Query must target the users table"
    end

    # Must select user ID
    unless query_upper.include?("ID") || query_upper.include?("USERS.ID")
      @errors << "Query must select user ID (id or users.id)"
    end

    # Check for balanced parentheses
    return if balanced_parentheses?

    @errors << "Query contains unbalanced parentheses"
  end

  def validate_forbidden_keywords
    return if @query.blank?

    query_upper = @query.upcase

    FORBIDDEN_KEYWORDS.each do |keyword|
      # Use word boundaries to avoid false positives
      pattern = /\b#{Regexp.escape(keyword)}\b/i
      if query_upper.match?(pattern)
        @errors << "Query contains forbidden keyword: #{keyword}"
      end
    end
  end

  def validate_suspicious_patterns
    return if @query.blank?

    SUSPICIOUS_PATTERNS.each do |pattern|
      if @query.match?(pattern)
        @errors << "Query contains suspicious pattern: #{pattern.inspect}"
      end
    end
  end

  def validate_table_access
    return if @query.blank?

    # Extract table names from FROM and JOIN clauses
    table_names = extract_table_names(@query)

    # Check that all referenced tables are allowed
    unauthorized_tables = table_names - ALLOWED_TABLES

    return if unauthorized_tables.empty?

    @errors << "Query references unauthorized tables: #{unauthorized_tables.join(', ')}"
  end

  def validate_read_only_operations
    return if @query.blank?

    query_upper = @query.upcase

    # Check for data modification keywords
    modifying_keywords = %w[INSERT UPDATE DELETE DROP CREATE ALTER TRUNCATE]

    modifying_keywords.each do |keyword|
      # Use word boundaries to avoid false positives
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
        return false if count < 0
      end
    end
    count == 0
  end

  def extract_table_names(query)
    # Simple regex to extract table names from FROM and JOIN clauses
    # This is a basic implementation and could be enhanced with a proper SQL parser
    table_names = []

    # Extract FROM clause tables
    from_matches = query.scan(/\bFROM\s+(\w+)/i)
    table_names.concat(from_matches.flatten.map(&:downcase))

    # Extract JOIN clause tables
    join_matches = query.scan(/\bJOIN\s+(\w+)/i)
    table_names.concat(join_matches.flatten.map(&:downcase))

    # Extract LEFT/RIGHT/INNER JOIN tables
    lr_join_matches = query.scan(/\b(?:LEFT|RIGHT|INNER)\s+JOIN\s+(\w+)/i)
    table_names.concat(lr_join_matches.flatten.map(&:downcase))

    table_names.uniq
  end
end
