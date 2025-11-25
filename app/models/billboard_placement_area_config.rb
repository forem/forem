class BillboardPlacementAreaConfig < ApplicationRecord
  validates :placement_area, presence: true, uniqueness: true,
                             inclusion: { in: Billboard::ALLOWED_PLACEMENT_AREAS }
  validates :signed_in_rate, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  validates :signed_out_rate, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  validates :cache_expiry_seconds, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 86_400, # Max 24 hours
    only_integer: true
  }, allow_nil: true
  validate :validate_selection_weights

  # Cache key for storing all configs
  CACHE_KEY = "billboard_placement_area_configs".freeze
  CACHE_EXPIRY = 1.hour

  # Default cache expiry for billboard responses (3 minutes)
  DEFAULT_BILLBOARD_CACHE_EXPIRY_SECONDS = 180

  # Default weights for billboard selection strategies
  # These are relative weights - they don't need to add up to 100
  DEFAULT_SELECTION_WEIGHTS = {
    "random_selection" => 5,           # Completely random selection (5%)
    "new_and_priority" => 30,          # New/priority billboards with fewer impressions (30%)
    "new_only" => 5,                   # Only new billboards (5%)
    "weighted_performance" => 60,      # Performance-based weighted selection (60%)
    "evenly_distributed" => 0          # Serves billboards with minimum impressions for even distribution (0% by default)
  }.freeze

  after_destroy :bust_cache
  after_save :bust_cache

  # Get delivery rate for a specific placement area and user state
  def self.delivery_rate_for(placement_area:, user_signed_in:)
    config = config_for_placement_area(placement_area)
    return 100 if config.blank? # Default to 100% if no config exists

    user_signed_in ? config.signed_in_rate : config.signed_out_rate
  end

  # Check if we should fetch a billboard based on delivery rate
  def self.should_fetch_billboard?(placement_area:, user_signed_in:)
    rate = delivery_rate_for(placement_area: placement_area, user_signed_in: user_signed_in)
    return true if rate >= 100 # Always fetch if rate is 100%
    return false if rate <= 0 # Never fetch if rate is 0%

    # Randomly decide based on the rate (e.g., 10% rate means 10% chance to fetch)
    rand(100) < rate
  end

  # Get config for a specific placement area (cached)
  def self.config_for_placement_area(placement_area)
    all_configs[placement_area]
  end

  # Get all configs (cached)
  def self.all_configs
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY) do
      all.index_by(&:placement_area)
    end
  end

  # Bust the cache when configs are modified
  def self.bust_cache
    Rails.cache.delete(CACHE_KEY)
  end

  # Get cache expiry seconds for a specific placement area
  # Returns the configured value or the default if not set
  def self.cache_expiry_seconds_for(placement_area)
    config = config_for_placement_area(placement_area)
    return DEFAULT_BILLBOARD_CACHE_EXPIRY_SECONDS if config.blank?

    # Use nil? check instead of presence to allow 0 (which disables caching)
    config.cache_expiry_seconds.nil? ? DEFAULT_BILLBOARD_CACHE_EXPIRY_SECONDS : config.cache_expiry_seconds
  end

  # Get selection weights for a specific placement area
  # Returns weights merged with defaults so missing keys get default values
  def self.selection_weights_for(placement_area)
    config = config_for_placement_area(placement_area)
    weights = config&.selection_weights || {}
    
    # Return defaults if weights is empty or nil
    return DEFAULT_SELECTION_WEIGHTS.dup if weights.blank?
    
    # Merge with defaults so any missing keys get default values
    # Filter out any negative values and replace with 0
    merged_weights = DEFAULT_SELECTION_WEIGHTS.merge(weights.symbolize_keys.transform_keys(&:to_s))
    merged_weights.transform_values { |v| [v.to_i, 0].max }
  end

  # Get or initialize weights from legacy ApplicationConfig
  # This backfills weights from the old ENV-based config
  def initialize_weights_from_app_config
    return if selection_weights.present? && !selection_weights.empty?

    # Convert old range-based config to new weight-based config
    # Old system: ranges (0-5, 5-35, 35-40, 40-99)
    # New system: relative weights that determine probability
    
    # Get the old range values or use defaults
    random_max = ApplicationConfig["SELDOM_SEEN_MIN_FOR_#{placement_area.upcase}"] ||
                 ApplicationConfig["SELDOM_SEEN_MIN"] ||
                 Billboard::RANDOM_RANGE_MAX_FALLBACK
    
    new_and_priority_max = ApplicationConfig["SELDOM_SEEN_MAX_FOR_#{placement_area.upcase}"] ||
                           ApplicationConfig["SELDOM_SEEN_MAX"] ||
                           Billboard::NEW_AND_PRIORITY_RANGE_MAX_FALLBACK
    
    new_only_max = ApplicationConfig["NEW_ONLY_MAX_FOR_#{placement_area.upcase}"] ||
                   ApplicationConfig["NEW_ONLY_MAX"] ||
                   Billboard::NEW_ONLY_RANGE_MAX_FALLBACK
    
    # Convert ranges to weights
    # Range 0-5 = 5% = weight 5
    # Range 5-35 = 30% = weight 30
    # Range 35-40 = 5% = weight 5
    # Range 40-99 = 60% = weight 60
    random_weight = random_max.to_i
    new_and_priority_weight = new_and_priority_max.to_i - random_max.to_i
    new_only_weight = new_only_max.to_i - new_and_priority_max.to_i
    weighted_performance_weight = 99 - new_only_max.to_i

    self.selection_weights = {
      "random_selection" => random_weight,
      "new_and_priority" => new_and_priority_weight,
      "new_only" => new_only_weight,
      "weighted_performance" => weighted_performance_weight
    }
  end

  # Get low impression count for this placement area
  def low_impression_count
    ApplicationConfig["LOW_IMPRESSION_COUNT_FOR_#{placement_area.upcase}"] ||
      ApplicationConfig["LOW_IMPRESSION_COUNT"] ||
      Billboard::LOW_IMPRESSION_COUNT
  end

  # Get human-readable name for placement area
  def human_readable_placement_area
    index = Billboard::ALLOWED_PLACEMENT_AREAS.find_index(placement_area)
    index ? Billboard::ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE[index] : placement_area
  end

  private

  def bust_cache
    self.class.bust_cache
  end

  def validate_selection_weights
    return if selection_weights.blank?
    
    unless selection_weights.is_a?(Hash)
      errors.add(:selection_weights, "must be a hash")
      return
    end

    # Check that all values are non-negative integers
    selection_weights.each do |key, value|
      unless value.is_a?(Integer) || value.is_a?(String) && value.to_i.to_s == value
        errors.add(:selection_weights, "#{key} must be an integer")
      end
      
      if value.to_i.negative?
        errors.add(:selection_weights, "#{key} cannot be negative")
      end
    end

    # Warn if all weights are zero (but don't fail validation)
    if selection_weights.values.all? { |v| v.to_i.zero? }
      Rails.logger.warn("All selection weights are zero for placement area #{placement_area}")
    end
  end
end
