class OnboardingsController < ApplicationController
  before_action :set_cache_control_headers
  TAG_ONBOARDING_ATTRIBUTES = %i[id name taggings_count].freeze

  def tags
    @tags = Tags::SuggestedForOnboarding.call
      .select(TAG_ONBOARDING_ATTRIBUTES)

    render json: @tags
    set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
  end
end
