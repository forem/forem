class AdditionalContentBoxesController < ApplicationController

  def index
    articles_ids = params[:article_id].split(",")
    @article = Article.find(articles_ids[0])
    @for_user_article = ClassicArticle.
      new(current_user || @article, {not_ids: articles_ids}).get
    if (!user_signed_in? || current_user&.display_sponsors) && @article.user.permit_adjacent_sponsors
      @boosted_article = BoostedArticle.
        new(current_user, @article, {not_ids: (articles_ids+[@for_user_article])}).get
    end
    @alt_classic = ClassicArticle.
      new(@article, {not_ids: (articles_ids+[@for_user_article])}).get unless @boosted_article
    render "boxes", layout: false
  end
end