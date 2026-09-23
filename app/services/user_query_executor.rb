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
    return User.none unless valid?

    # Validate variables if provided
    if user_query.has_variables?
      substitutor = UserQueryVariableSubstitutor.new(user_query, variables)
      unless substitutor.valid?
        @errors.concat(substitutor.error_messages)
        return User.none
      end
    end

    # Validate query safety before execution
    final_query = user_query.substitute_variables(variables)
    validator = UserQueryValidator.new(final_query)
    unless validator.valid?
      @errors.concat(validator.error_messages)
      return User.none
    end

    execute_safe_query
  end

  def execute!
    validate_query_and_variables!

    users = execute_safe_query
    if @errors.any?
      error_class = if @errors.any? { |m| m.include?("maximum time limit") }
                      UserQuery::QueryTimeoutError
                    else
                      UserQuery::QueryExecutionError
                    end
      raise error_class, @errors.join("; ")
    end

    users
  end

  def each_id_batch(batch_size: 1000, &block)
    return unless block

    validate_query_and_variables!

    final_query = user_query.substitute_variables(variables)
    executed_successfully = false

    ReadOnlyDatabaseService.with_connection do |conn|
      setup_execution_environment(conn)
      safe_query = build_safe_query(final_query)

      begin
        result = execute_with_timeout(conn, safe_query)
        if result.is_a?(PG::Result)
          process_id_batches(result, batch_size, &block)
          executed_successfully = true
        end
      rescue PG::QueryCanceled, ActiveRecord::QueryCanceled => e
        handle_timeout_error(e)
        raise UserQuery::QueryTimeoutError, "Query execution exceeded maximum time limit of #{timeout_ms}ms"
      rescue StandardError => e
        handle_execution_error(e)
        raise UserQuery::QueryExecutionError, "Query execution failed: #{e.message}"
      end
    end

    update_execution_tracking if executed_successfully
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
    user_ids = []

    ReadOnlyDatabaseService.with_connection do |conn|
      setup_execution_environment(conn)
      final_query = user_query.substitute_variables(variables)
      safe_query = build_safe_query(final_query)

      begin
        conn.transaction(requires_new: true) do
          result = execute_with_timeout(conn, safe_query)
          user_ids = extract_user_ids(result)
        end
      rescue PG::QueryCanceled, ActiveRecord::QueryCanceled => e
        handle_timeout_error(e)
        return User.none
      rescue PG::SyntaxError => e
        handle_syntax_error(e)
        return User.none
      rescue StandardError => e
        handle_execution_error(e)
        return User.none
      end
    end

    update_execution_tracking if @errors.empty?
    User.where(id: user_ids)
  end

  def setup_execution_environment(connection)
    connection.execute("SET statement_timeout = #{timeout_ms}")
    connection.execute("SET lock_timeout = #{timeout_ms}")
    connection.execute("SET idle_in_transaction_session_timeout = #{timeout_ms * 2}")
    connection.execute("SET row_security = on")
  end

  def build_safe_query(base_query = nil)
    query_text = (base_query || user_query.query).to_s.strip
    query_text += ";" unless query_text.end_with?(";")

    if limit
      query_text = query_text.gsub(/\s+LIMIT\s+\d+;?$/i, "")
      query_text = query_text.chomp(";") + " LIMIT #{[limit, MAX_USER_LIMIT].min};"
    end

    query_text
  end

  def build_explain_query
    final_query = user_query.substitute_variables(variables)
    base_query = build_safe_query(final_query)
    "EXPLAIN (FORMAT JSON) #{base_query.chomp(';')}"
  end

  def execute_with_timeout(connection, query)
    connection.execute(query)
  end

  def execute_explain_query(explain_query)
    ReadOnlyDatabaseService.with_connection do |conn|
      conn.transaction(requires_new: true) do
        conn.execute(explain_query)
      end
    end
  rescue StandardError => e
    Rails.logger.warn("EXPLAIN query failed: #{e.message}")
    nil
  end

  def extract_user_ids(result)
    return [] unless result.is_a?(PG::Result)

    user_ids = []
    result.each do |row|
      user_id = row["id"] || row["user_id"] || row["users.id"]
      user_ids << user_id.to_i if user_id
    end

    user_ids.uniq
  end

  def extract_estimated_rows(result)
    return 0 unless result.is_a?(PG::Result) && result.ntuples.positive?

    raw_plan = result.first["QUERY PLAN"]
    plan_data = if raw_plan.is_a?(String)
                  JSON.parse(raw_plan)
                else
                  raw_plan
                end

    return 0 unless plan_data.is_a?(Array) && plan_data.first.is_a?(Hash)

    root_plan = plan_data.first["Plan"]
    return 0 unless root_plan.is_a?(Hash)

    plan_rows = root_plan["Plan Rows"]
    return 0 unless plan_rows

    [plan_rows.to_i, 0].max
  rescue StandardError => e
    Rails.logger.warn("Failed to parse EXPLAIN plan: #{e.message}")
    0
  end

  def validate_query_and_variables!
    unless valid?
      raise UserQuery::QueryValidationError, "Invalid user query: #{error_messages.join(', ')}"
    end

    if user_query.has_variables?
      substitutor = UserQueryVariableSubstitutor.new(user_query, variables)
      unless substitutor.valid?
        @errors.concat(substitutor.error_messages)
        raise UserQuery::QueryValidationError, "Invalid variables: #{substitutor.error_messages.join(', ')}"
      end
    end

    final_query = user_query.substitute_variables(variables)
    validator = UserQueryValidator.new(final_query)
    return if validator.valid?

    @errors.concat(validator.error_messages)
    raise UserQuery::QueryValidationError, "Query validation failed: #{validator.error_messages.join(', ')}"
  end

  def process_id_batches(result, batch_size)
    current_batch = []
    result.each do |row|
      user_id = row["id"] || row["user_id"] || row["users.id"]
      next unless user_id

      current_batch << user_id.to_i

      if current_batch.size >= batch_size
        yield current_batch
        current_batch = []
      end
    end

    yield current_batch if current_batch.any?
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
