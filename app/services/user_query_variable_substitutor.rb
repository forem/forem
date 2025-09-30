class UserQueryVariableSubstitutor
  include ActiveModel::Validations
  
  # Allowed variable types
  ALLOWED_TYPES = %w[string integer boolean array].freeze
  
  # Maximum number of variables allowed per query
  MAX_VARIABLES = 10
  
  # Maximum length of variable names and values
  MAX_VARIABLE_NAME_LENGTH = 50
  MAX_VARIABLE_VALUE_LENGTH = 1000
  
  attr_reader :user_query, :variables, :errors
  
  def initialize(user_query, variables = {})
    @user_query = user_query
    @variables = variables.with_indifferent_access
    @errors = []
  end
  
  def valid?
    @errors.clear
    validate_variable_definitions
    validate_variable_values
    validate_variable_substitution
    @errors.empty?
  end
  
  def error_messages
    @errors
  end
  
  def substituted_query
    return user_query.query unless user_query.variable_definitions.present?
    
    begin
      definitions = JSON.parse(user_query.variable_definitions)
      substituted = user_query.query.dup
      
      definitions.each do |var_name, var_def|
        value = get_variable_value(var_name, var_def)
        substituted = substitute_variable(substituted, var_name, value)
      end
      
      substituted
    rescue JSON::ParserError => e
      @errors << "Invalid variable definitions JSON: #{e.message}"
      user_query.query
    rescue => e
      @errors << "Variable substitution error: #{e.message}"
      user_query.query
    end
  end
  
  def required_variables
    return {} unless user_query.variable_definitions.present?
    
    begin
      JSON.parse(user_query.variable_definitions)
    rescue JSON::ParserError
      {}
    end
  end
  
  def missing_variables
    required = required_variables
    missing = {}
    
    required.each do |var_name, var_def|
      unless variables.key?(var_name)
        missing[var_name] = var_def
      end
    end
    
    missing
  end
  
  private
  
  def validate_variable_definitions
    return unless user_query.variable_definitions.present?
    
    begin
      definitions = JSON.parse(user_query.variable_definitions)
      
      unless definitions.is_a?(Hash)
        @errors << "Variable definitions must be a JSON object"
        return
      end
      
      if definitions.size > MAX_VARIABLES
        @errors << "Maximum #{MAX_VARIABLES} variables allowed"
      end
      
      definitions.each do |var_name, var_def|
        validate_variable_definition(var_name, var_def)
      end
    rescue JSON::ParserError => e
      @errors << "Invalid variable definitions JSON: #{e.message}"
    end
  end
  
  def validate_variable_definition(var_name, var_def)
    unless var_name.is_a?(String) && var_name.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*\z/)
      @errors << "Variable name '#{var_name}' must be a valid identifier"
    end
    
    if var_name.length > MAX_VARIABLE_NAME_LENGTH
      @errors << "Variable name '#{var_name}' exceeds maximum length"
    end
    
    unless var_def.is_a?(Hash)
      @errors << "Variable definition for '#{var_name}' must be an object"
      return
    end
    
    unless var_def['type'].in?(ALLOWED_TYPES)
      @errors << "Variable '#{var_name}' has invalid type '#{var_def['type']}'"
    end
    
    if var_def['required'] && variables[var_name].blank?
      @errors << "Required variable '#{var_name}' is missing"
    end
  end
  
  def validate_variable_values
    variables.each do |var_name, value|
      validate_variable_value(var_name, value)
    end
  end
  
  def validate_variable_value(var_name, value)
    required_vars = required_variables
    
    unless required_vars.key?(var_name)
      @errors << "Unknown variable '#{var_name}'"
      return
    end
    
    var_def = required_vars[var_name]
    validate_value_type(var_name, value, var_def['type'])
  end
  
  def validate_value_type(var_name, value, expected_type)
    case expected_type
    when 'string'
      unless value.is_a?(String)
        @errors << "Variable '#{var_name}' must be a string"
      end
    when 'integer'
      unless value.is_a?(Integer) || (value.is_a?(String) && value.match?(/\A-?\d+\z/))
        @errors << "Variable '#{var_name}' must be an integer"
      end
    when 'boolean'
      unless [true, false, 'true', 'false', '1', '0'].include?(value)
        @errors << "Variable '#{var_name}' must be a boolean"
      end
    when 'array'
      unless value.is_a?(Array) || (value.is_a?(String) && value.include?(','))
        @errors << "Variable '#{var_name}' must be an array or comma-separated string"
      end
    end
    
    if value.is_a?(String) && value.length > MAX_VARIABLE_VALUE_LENGTH
      @errors << "Variable '#{var_name}' value exceeds maximum length"
    end
  end
  
  def validate_variable_substitution
    return unless valid_variable_definitions?
    
    begin
      substituted = substituted_query
      # Basic validation that substitution didn't break the query structure
      unless substituted.include?('SELECT') && substituted.include?('FROM')
        @errors << "Variable substitution resulted in invalid query structure"
      end
    rescue => e
      @errors << "Variable substitution validation failed: #{e.message}"
    end
  end
  
  def valid_variable_definitions?
    begin
      JSON.parse(user_query.variable_definitions).is_a?(Hash)
    rescue JSON::ParserError
      false
    end
  end
  
  def get_variable_value(var_name, var_def)
    value = variables[var_name]
    
    # Handle default values
    if value.blank? && var_def['default']
      value = var_def['default']
    end
    
    # Convert value to appropriate type
    case var_def['type']
    when 'string'
      value.to_s
    when 'integer'
      value.to_i
    when 'boolean'
      convert_to_boolean(value)
    when 'array'
      convert_to_array(value)
    else
      value
    end
  end
  
  def substitute_variable(query, var_name, value)
    # Replace {{variable_name}} patterns with the actual value
    # Use proper SQL escaping based on the value type
    escaped_value = escape_value_for_sql(value)
    query.gsub(/\{\{#{Regexp.escape(var_name)}\}\}/, escaped_value)
  end
  
  def escape_value_for_sql(value)
    case value
    when String
      ActiveRecord::Base.connection.quote(value)
    when Integer
      value.to_s
    when TrueClass, FalseClass
      value.to_s.upcase
    when Array
      # For arrays, create a comma-separated quoted list
      value.map { |v| ActiveRecord::Base.connection.quote(v.to_s) }.join(', ')
    else
      ActiveRecord::Base.connection.quote(value.to_s)
    end
  end
  
  def convert_to_boolean(value)
    case value
    when true, 'true', '1', 1
      true
    when false, 'false', '0', 0
      false
    else
      false
    end
  end
  
  def convert_to_array(value)
    case value
    when Array
      value
    when String
      value.split(',').map(&:strip)
    else
      [value.to_s]
    end
  end
end


