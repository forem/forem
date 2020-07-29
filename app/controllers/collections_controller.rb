class CollectionsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index show]

  def index
    @user = User.find_by!(username: params[:username])
    @collections = @user.collections.includes(:articles).order(created_at: :desc)
    @articles = Article.published.where(collection_id: @collections.pluck(:id))
    set_surrogate_key_header Article.table_key, @articles.map(&:record_key)
  end

  def show
    @collection = Collection.find(params[:id])
    @user = @collection.user
    @articles = @collection.articles.published.order(Arel.sql("COALESCE(crossposted_at, published_at) ASC"))
    set_surrogate_key_header Article.table_key, @articles.map(&:record_key)
  end
end
