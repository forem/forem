class CollectionsController < ApplicationController
  def index
    @user = User.find_by!(username: params[:username])
    @collections = @user.collections.non_empty.order(created_at: :desc)
  end

  def show
    @collection = Collection.find_by(id: params[:id])
    unless @collection
      collection_id_alias = CollectionIdAlias.find_by(legacy_collection_id: params[:id])

      if collection_id_alias&.collection
        return redirect_to collection_id_alias.collection.path, status: :moved_permanently
      end

      raise ActiveRecord::RecordNotFound
    end

    @user = @collection.user
    @articles = @collection.articles.from_subforem.published.order(Arel.sql("COALESCE(crossposted_at, published_at) ASC"))
  end
end
