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
  validate :query_must_be_safe_and_valid

  scope :active, -> { where(active: true) }
  scope :recently_executed, -> { where.not(last_executed_at: nil).order(last_executed_at: :desc) }

  # Maximum number of users that can be returned by a query
  MAX_USER_LIMIT = 100_000

  # Allowed SQL keywords and functions for user queries
  ALLOWED_KEYWORDS = UserQueryValidator::ALLOWED_KEYWORDS
  FORBIDDEN_KEYWORDS = UserQueryValidator::FORBIDDEN_KEYWORDS

  # Custom error classes
  class QueryValidationError < StandardError; end
  class QueryExecutionError < StandardError; end
  class QueryTimeoutError < StandardError; end

  def execute_safely(limit: nil, variables: {})
    return User.none unless active?

    validate_query_safety!

    executor = UserQueryExecutor.new(self, limit: limit, variables: variables)
    executor.execute!
  end

  def estimated_user_count
    return 0 unless active?

    UserQueryExecutor.new(self).estimated_count
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

  def build_safe_query(base_query = nil, limit = nil)
    query_with_limit = (base_query || query).to_s.strip
    query_with_limit += ";" unless query_with_limit.end_with?(";")

    if limit
      query_with_limit = query_with_limit.gsub(/\s+LIMIT\s+\d+;?$/i, "")
      query_with_limit = query_with_limit.chomp(";") + " LIMIT #{[limit, MAX_USER_LIMIT].min};"
    end

    query_with_limit
  end

  private

  def query_must_be_safe_and_valid
    return if query.blank?

    validator = UserQueryValidator.new(query)
    return if validator.valid?

    validator.error_messages.each do |message|
      clean_message = message.sub(/^Query\s+/i, "")
      errors.add(:query, clean_message)
    end
  end

  def validate_query_safety!
    return if valid?

    raise QueryValidationError, "Query validation failed: #{errors.full_messages.join(', ')}"
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
      parsed = JSON.parse(variables)
      unless parsed.is_a?(Hash)
        errors.add(:variables, "must be a valid JSON object")
      end
    rescue JSON::ParserError => e
      errors.add(:variables, "must be valid JSON: #{e.message}")
    end
  end
end
