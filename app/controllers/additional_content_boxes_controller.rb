class AdditionalContentBoxesController < ApplicationController
  def index
    article_ids = params[:article_id].split(",")
    @article = Article.find(article_ids[0])
    @for_user_article = ClassicArticle.
      new(current_user || @article, not_ids: article_ids).get
    if (!user_signed_in? || current_user&.display_sponsors) &&
        @article.user.permit_adjacent_sponsors &&
        rand(2) == 1
      @boosted_article = BoostedArticle.
        new(current_user, @article, not_ids: (article_ids + [@for_user_article])).get
    else
      @alt_classic = ClassicArticle.
        new(@article, not_ids: (article_ids + [@for_user_article])).get
    end
    render "boxes", layout: false
  end
end
