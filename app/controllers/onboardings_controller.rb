class OnboardingsController < ApplicationController
  before_action :set_cache_control_headers

  def tags
    @tags = Tags::SuggestedForOnboarding.call
      .select_attributes_for_serialization

    set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
  end
end
