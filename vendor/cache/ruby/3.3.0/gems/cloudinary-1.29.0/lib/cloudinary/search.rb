class Cloudinary::Search
  ENDPOINT = 'resources'

  SORT_BY    = :sort_by
  AGGREGATE  = :aggregate
  WITH_FIELD = :with_field
  FIELDS     = :fields
  KEYS_WITH_UNIQUE_VALUES = [SORT_BY, AGGREGATE, WITH_FIELD, FIELDS].freeze

  TTL = 300 # Used for search URLs

  def initialize
    @query_hash = {
      SORT_BY    => {},
      AGGREGATE  => {},
      WITH_FIELD => {},
      FIELDS => {},
    }

    @endpoint = self.class::ENDPOINT

    @ttl = self.class::TTL
  end

  ## implicitly generate an instance delegate the method
  def self.method_missing(method_name, *arguments)
    instance = new
    instance.send(method_name, *arguments)
  end

  def expression(value)
    @query_hash[:expression] = value
    self
  end

  def max_results(value)
    @query_hash[:max_results] = value
    self
  end

  def next_cursor(value)
    @query_hash[:next_cursor] = value
    self
  end

  # Sets the `sort_by` field.
  #
  # @param [String] field_name   The field to sort by. You can specify more than one sort_by parameter;
  #                              results will be sorted according to the order of the fields provided.
  # @param [String] dir          Sort direction. Valid sort directions are 'asc' or 'desc'. Default: 'desc'.
  #
  # @return [Cloudinary::Search]
  def sort_by(field_name, dir = 'desc')
    @query_hash[SORT_BY][field_name] = { field_name => dir }
    self
  end

  # The name of a field (attribute) for which an aggregation count should be calculated and returned in the response.
  #
  # You can specify more than one aggregate parameter.
  #
  # @param [String] value  Supported values: resource_type, type, pixels (only the image assets in the response are
  #                        aggregated), duration (only the video assets in the response are aggregated), format, and
  #                        bytes. For aggregation fields without discrete values, the results are divided into
  #                        categories.
  # @return [Cloudinary::Search]
  def aggregate(value)
    @query_hash[AGGREGATE][value] = value
    self
  end

  # The name of an additional asset attribute to include for each asset in the response.
  #
  # @param [String] value Possible value: context, tags, and for Tier 2 also image_metadata, and image_analysis.
  #
  # @return [Cloudinary::Search]
  def with_field(value)
    @query_hash[WITH_FIELD][value] = value
    self
  end


  # The list of the asset attributes to include for each asset in the response.
  #
  # @param [Array] value The array of attributes' names.
  #
  # @return [Cloudinary::Search]
  def fields(value)
    Cloudinary::Utils.build_array(value).each do |field|
      @query_hash[FIELDS][field] = field
    end
    self
  end

  # Sets the time to live of the search URL.
  #
  # @param [Object] ttl The time to live in seconds.
  #
  # @return [Cloudinary::Search]
  def ttl(ttl)
    @ttl = ttl
    self
  end

  # Returns the query as an hash.
  #
  # @return [Hash]
  def to_h
    @query_hash.sort.each_with_object({}) do |(key, value), query|
      next if value.nil? || ((value.is_a?(Array) || value.is_a?(Hash)) && value.blank?)

      query[key] = KEYS_WITH_UNIQUE_VALUES.include?(key) ? value.values : value
    end
  end

  def execute(options = {})
    options[:content_type] = :json
    uri = "#{@endpoint}/search"
    Cloudinary::Api.call_api(:post, uri, to_h, options)
  end

  # Creates a signed Search URL that can be used on the client side.
  #
  # @param [Integer] ttl The time to live in seconds.
  # @param [String] next_cursor Starting position.
  # @param [Hash] options Additional url delivery options.
  #
  # @return [String] The resulting Search URL
  def to_url(ttl = nil, next_cursor = nil, options = {})
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise(CloudinaryException, "Must supply api_secret")

    ttl   = ttl || @ttl
    query = self.to_h

    _next_cursor = query.delete(:next_cursor)
    next_cursor  = _next_cursor if next_cursor.nil?

    b64query = Base64.urlsafe_encode64(JSON.generate(query))

    prefix = Cloudinary::Utils.build_distribution_domain(options)

    signature = Cloudinary::Utils.hash("#{ttl}#{b64query}#{api_secret}", :sha256, :hexdigest)

    next_cursor = "/#{next_cursor}" if !next_cursor.nil? && !next_cursor.empty?

    "#{prefix}/search/#{signature}/#{ttl}/#{b64query}#{next_cursor}"
  end

  # Sets the API endpoint.
  #
  # @param [String] endpoint the endpoint to set.
  #
  # @return [Cloudinary::Search]
  def endpoint(endpoint)
    @endpoint = endpoint
    self
  end
end
