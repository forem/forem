class DisplayAdsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[for_display], unless: -> { current_user }
  CACHE_EXPIRY_FOR_DISPLAY_ADS = 15.minutes.to_i.freeze

  def for_display
    skip_authorization
    set_cache_control_headers(CACHE_EXPIRY_FOR_DISPLAY_ADS)

    if params[:article_id]
      @article = Article.find(params[:article_id])

      @display_ad = DisplayAd.for_display(
        area: "post_comments",
        user_signed_in: user_signed_in?,
        organization_id: @article.organization_id,
        permit_adjacent_sponsors: @article.decorate.permit_adjacent_sponsors?,
        article_tags: @article.decorate.cached_tag_list_array,
      )
    end

    # set_surrogate_key_header "display_ad"
    render layout: false
  end
end
