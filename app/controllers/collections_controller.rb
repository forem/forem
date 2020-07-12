class CollectionsController < ApplicationController
  def index
    @user = User.find_by!(username: params[:username])
    @collections = @user.collections.order(created_at: :desc)
  end

  def show
    @user = User.find_by!(username: params[:username])
    @collection = @user.collections.find_by!(slug: params[:slug])
    @articles = @collection.articles.published.order(Arel.sql("COALESCE(crossposted_at, published_at) ASC"))
  end
end
