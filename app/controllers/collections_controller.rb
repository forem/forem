class CollectionsController < ApplicationController
  ARTICLES_PER_PAGE = 30

  def index
    @user = User.find_by!(username: params[:username])
    @collections = @user.collections.non_empty.order(created_at: :desc)
  end

  def show
    @collection = Collection.find(params[:id])
    @user = @collection.user
    @articles = @collection.articles.from_subforem.published
      .includes(:context_notes)
      .order(Arel.sql("COALESCE(crossposted_at, published_at) ASC, articles.id ASC"))
      .page(params[:page]).per(ARTICLES_PER_PAGE)
  end
end
