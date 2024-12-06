require 'multi_json'

module Helpers
  # Convert an Hash to json
  #
  def to_json(body)
    body.is_a?(String) ? body : MultiJson.dump(body)
  end

  # Converts each key of a hash to symbols
  #
  def symbolize_hash(hash)
    hash.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
  end

  # Convert params to a full query string
  #
  def handle_params(params)
    params.nil? || params.empty? ? '' : "?#{to_query_string(params)}"
  end

  # Create a query string from params
  #
  def to_query_string(params)
    params.map do |key, value|
      "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
    end.join('&')
  end

  # Convert a json object to an hash
  #
  def json_to_hash(json, symbolize_keys)
    MultiJson.load(json, symbolize_keys: symbolize_keys)
  end

  # Retrieve the given value associated with a key, in string or symbol format
  #
  def get_option(hash, key)
    hash[key.to_sym] || hash[key] || nil
  end

  # Build a path with the given arguments
  #
  def path_encode(path, *args)
    arguments = []
    args.each do |arg|
      arguments.push(CGI.escape(arg.to_s))
    end

    format(path, *arguments)
  end

  # Support to convert old settings to their new names
  #
  def deserialize_settings(data, symbolize_keys)
    settings = data
    keys     = {
      attributesToIndex: 'searchableAttributes',
      numericAttributesToIndex: 'numericAttributesForFiltering',
      slaves: 'replicas'
    }

    keys.each do |deprecated_key, current_key|
      deprecated_key = symbolize_keys ? deprecated_key : deprecated_key.to_s
      if settings.has_key?(deprecated_key)
        key           = symbolize_keys ? current_key.to_sym : current_key.to_s
        settings[key] = settings.delete(deprecated_key)
      end
    end

    settings
  end

  def self.included(base)
    base.extend(Helpers)
  end

  def hash_includes_subset?(hash, subset)
    res = true
    subset.each do |k, v|
      res &&= hash[k] == v
    end
    res
  end

  # Check the passed object to determine if it's an array
  #
  # @param object [Object]
  #
  def check_array(object)
    raise Algolia::AlgoliaError, 'argument must be an array of objects' unless object.is_a?(Array)
  end

  # Check the passed object
  #
  # @param object [Object]
  # @param in_array [Boolean] whether the object is an array or not
  #
  def check_object(object, in_array = false)
    case object
    when Array
      raise Algolia::AlgoliaError, in_array ? 'argument must be an array of objects' : 'argument must not be an array'
    when String, Integer, Float, TrueClass, FalseClass, NilClass
      raise Algolia::AlgoliaError, "argument must be an #{'array of' if in_array} object, got: #{object.inspect}"
    end
  end

  # Check if passed object has a objectID
  #
  # @param object [Object]
  # @param object_id [String]
  #
  def get_object_id(object, object_id = nil)
    check_object(object)
    object_id ||= object[:objectID] || object['objectID']
    raise Algolia::AlgoliaError, "Missing 'objectID'" if object_id.nil?
    object_id
  end

  # Build a batch request
  #
  # @param action [String] action to perform on the engine
  # @param objects [Array] objects on which build the action
  # @param with_object_id [Boolean] if set to true, check if each object has an objectID set
  #
  def chunk(action, objects, with_object_id = false)
    objects.map do |object|
      check_object(object, true)
      request            = { action: action, body: object }
      request[:objectID] = get_object_id(object).to_s if with_object_id
      request
    end
  end
end
