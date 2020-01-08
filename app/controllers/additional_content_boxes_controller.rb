class AdditionalContentBoxesController < ApplicationController
  # No authorization required for entirely public controller

  before_action :set_cache_control_headers, only: [:index]

  def index
    return head :unprocessable_entity if params[:article_id].blank?

    article_ids = params[:article_id].split(",")
    @article = Article.find(article_ids[0])

    @suggested_articles = Suggester::Articles::Classic.new(@article, not_ids: article_ids).get(2)

    if (!user_signed_in? || params[:state] == "include_sponsors") &&
        @article.user.permit_adjacent_sponsors &&
        randomize

      tag = (@article.decorate.cached_tag_list_array + @article.boosted_additional_tags.split).sample
      not_ids = article_ids + @suggested_articles.pluck(:id)
      @boosted_article = Suggester::Articles::Boosted.new(tag, not_ids: not_ids, area: "additional_articles").suggest
    end

    set_surrogate_key_header "additional_content_boxes_" + params.to_s
    render "boxes", layout: false
  end

  private

  def randomize
    return true unless Rails.env.production?

    rand(2) == 1
  end
end
