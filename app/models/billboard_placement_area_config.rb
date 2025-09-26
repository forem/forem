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

  # Cache key for storing all configs
  CACHE_KEY = "billboard_placement_area_configs".freeze
  CACHE_EXPIRY = 1.hour

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

  private

  def bust_cache
    self.class.bust_cache
  end
end
