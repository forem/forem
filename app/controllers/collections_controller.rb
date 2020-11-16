class CollectionsController < ApplicationController
  def index
    @user = User.find_by!(username: params[:username])
    @collections = @user.collections.joins(:articles).distinct.order(created_at: :desc)
  end

  def show
    @collection = Collection.find(params[:id])
    @user = @collection.user
    @articles = @collection.articles.published.order(Arel.sql("COALESCE(crossposted_at, published_at) ASC"))
  end
end
