class UserQueryExecutor
  include ActiveModel::Validations

  # Default timeout for query execution (30 seconds)
  DEFAULT_TIMEOUT_MS = 30_000

  # Maximum timeout allowed (5 minutes)
  MAX_TIMEOUT_MS = 300_000

  # Maximum number of users that can be returned
  MAX_USER_LIMIT = 100_000

  # Maximum number of users for test executions
  MAX_TEST_USER_LIMIT = 100

  attr_reader :user_query, :timeout_ms, :limit, :variables, :errors

  def initialize(user_query, timeout_ms: nil, limit: nil, variables: {})
    @user_query = user_query
    @timeout_ms = timeout_ms || user_query&.max_execution_time_ms || DEFAULT_TIMEOUT_MS
    @limit = limit
    @variables = variables.with_indifferent_access
    @errors = []

    validate_inputs
  end

  def execute
    return [] unless valid?

    # Validate variables if provided
    if user_query.has_variables?
      substitutor = UserQueryVariableSubstitutor.new(user_query, variables)
      unless substitutor.valid?
        @errors.concat(substitutor.error_messages)
        return []
      end
    end

    # Validate query safety before execution
    final_query = user_query.substitute_variables(variables)
    validator = UserQueryValidator.new(final_query)
    unless validator.valid?
      @errors.concat(validator.error_messages)
      return []
    end

    # Execute the query safely
    execute_safe_query
  end

  def test_execute(limit: MAX_TEST_USER_LIMIT)
    @limit = limit
    execute
  end

  def estimated_count
    return 0 unless valid?

    begin
      explain_query = build_explain_query
      result = execute_explain_query(explain_query)

      # Extract estimated rows from the query plan
      extract_estimated_rows(result)
    rescue StandardError => e
      Rails.logger.warn("Could not estimate user count for query #{user_query.name}: #{e.message}")
      0
    end
  end

  def valid?
    @errors.empty? && validate_inputs
  end

  def error_messages
    @errors
  end

  private

  def validate_inputs
    @errors.clear

    if user_query.blank?
      @errors << "User query cannot be blank"
    elsif !user_query.active?
      @errors << "User query is not active"
    end

    if timeout_ms <= 0 || timeout_ms > MAX_TIMEOUT_MS
      @errors << "Timeout must be between 1 and #{MAX_TIMEOUT_MS} milliseconds"
    end

    if limit && (limit <= 0 || limit > MAX_USER_LIMIT)
      @errors << "Limit must be between 1 and #{MAX_USER_LIMIT}"
    end

    @errors.empty?
  end

  def execute_safe_query
    connection = nil

    # Use read-only database if available, otherwise fall back to main database
    ReadOnlyDatabaseService.with_connection do |conn|
      connection = conn

      # Set up execution environment
      setup_execution_environment(conn)

      # Build the safe query with variable substitution
      final_query = user_query.substitute_variables(variables)
      safe_query = build_safe_query(final_query)

      begin
        # Execute the query with timeout protection
        result = execute_with_timeout(conn, safe_query)

        # Extract user IDs from the result
        user_ids = extract_user_ids(result)

        # Update execution tracking (this still uses the main database)
        update_execution_tracking

        # Return User objects for the found IDs (this still uses the main database)
        User.where(id: user_ids)
      rescue PG::QueryCanceled => e
        handle_timeout_error(e)
        []
      rescue PG::SyntaxError => e
        handle_syntax_error(e)
        []
      rescue StandardError => e
        handle_execution_error(e)
        []
      end
    end
  end

  def setup_execution_environment(connection)
    # Set statement timeout
    connection.execute("SET statement_timeout = #{timeout_ms}")

    # Set other safety parameters
    connection.execute("SET lock_timeout = #{timeout_ms}")
    connection.execute("SET idle_in_transaction_session_timeout = #{timeout_ms * 2}")

    # Disable potentially dangerous functions
    connection.execute("SET row_security = on")
  end

  def build_safe_query(base_query = nil)
    query_text = base_query || user_query.query.strip

    # Ensure query ends with semicolon
    query_text += ";" unless query_text.end_with?(";")

    # Add LIMIT if specified
    if limit
      # Remove any existing LIMIT clause and add our limit
      query_text = query_text.gsub(/\s+LIMIT\s+\d+;?$/i, "")
      query_text = query_text.chomp(";") + " LIMIT #{[limit, MAX_USER_LIMIT].min};"
    end

    query_text
  end

  def build_explain_query
    base_query = build_safe_query
    "EXPLAIN (FORMAT JSON) #{base_query.chomp(';')}"
  end

  def execute_with_timeout(connection, query)
    # Use a separate thread with timeout to execute the query
    result = nil
    error = nil

    thread = Thread.new do
      result = connection.execute(query)
    rescue StandardError => e
      error = e
    end

    # Wait for the thread to complete or timeout
    unless thread.join(timeout_ms / 1000.0)
      thread.kill
      raise PG::QueryCanceled, "Query execution exceeded timeout of #{timeout_ms}ms"
    end

    if error
      raise error
    end

    result
  end

  def execute_explain_query(explain_query)
    ActiveRecord::Base.connection_pool.with_connection do |conn|
      conn.execute(explain_query)
    end
  end

  def extract_user_ids(result)
    return [] unless result.is_a?(PG::Result)

    user_ids = []
    result.each do |row|
      # Handle different possible column names for user ID
      user_id = row["id"] || row["user_id"] || row["users.id"]
      if user_id
        user_ids << user_id.to_i
      end
    end

    user_ids.uniq
  end

  def extract_estimated_rows(result)
    return 0 unless result.is_a?(PG::Result) && result.ntuples > 0

    plan_data = result.first["QUERY PLAN"]
    return 0 unless plan_data.is_a?(Array) && plan_data.first.is_a?(Hash)

    plan = plan_data.first
    extract_rows_from_plan(plan)
  end

  def extract_rows_from_plan(plan)
    # Recursively extract the maximum estimated rows from the query plan
    max_rows = 0

    if plan["Plan Rows"]
      max_rows = [max_rows, plan["Plan Rows"].to_i].max
    end

    if plan["Plans"] && plan["Plans"].is_a?(Array)
      plan["Plans"].each do |sub_plan|
        max_rows = [max_rows, extract_rows_from_plan(sub_plan)].max
      end
    end

    max_rows
  end

  def update_execution_tracking
    user_query.update!(
      last_executed_at: Time.current,
      execution_count: user_query.execution_count + 1,
    )
  end

  def handle_timeout_error(error)
    error_message = "Query execution exceeded maximum time limit of #{timeout_ms}ms"
    Rails.logger.error("UserQuery execution timeout: #{user_query.name} - #{error.message}")
    @errors << error_message
  end

  def handle_syntax_error(error)
    error_message = "Query syntax error: #{error.message}"
    Rails.logger.error("UserQuery syntax error: #{user_query.name} - #{error.message}")
    @errors << error_message
  end

  def handle_execution_error(error)
    error_message = "Query execution failed: #{error.message}"
    Rails.logger.error("UserQuery execution error: #{user_query.name} - #{error.message}")
    @errors << error_message
  end
end
