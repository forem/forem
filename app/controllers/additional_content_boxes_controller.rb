class AdditionalContentBoxesController < ApplicationController
  # No authorization required for entirely public controller

  before_action :set_cache_control_headers, only: [:index], unless: -> { current_user }

  def index
    article_ids = params[:article_id].split(",")
    @article = Article.find(article_ids[0])
    @for_user_article = Suggester::Articles::Classic.
      new(current_user || @article, not_ids: article_ids).get
    if (!user_signed_in? || current_user&.display_sponsors) &&
        @article.user.permit_adjacent_sponsors &&
        randomize
      @boosted_article = Suggester::Articles::Boosted.new(
        current_user,
        @article,
        not_ids: (article_ids + [@for_user_article&.id]), area: "additional_articles",
      ).suggest
    else
      @alt_classic = Suggester::Articles::Classic.
        new(@article, not_ids: (article_ids + [@for_user_article&.id])).get
    end
    set_surrogate_key_header "additional_content_boxes_" + params.to_s unless current_user
    render "boxes", layout: false
  end

  def randomize
    return true unless Rails.env.production?

    rand(2) == 1
  end
end
