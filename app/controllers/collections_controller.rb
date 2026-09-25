class CollectionsController < ApplicationController
  def index
    @user = User.find_by!(username: params[:username])
    @collections = @user.collections.non_empty.order(created_at: :desc)
  end

  def show
  @collection = Collection.find_by(id: params[:id]) ||
                Collection.find_by(slug: params[:id])

  not_found unless @collection

  # Redirect only if accessed via ID
  if params[:id].to_i.to_s == params[:id]
    return redirect_to "/#{params[:username]}/series/#{@collection.slug}", status: :moved_permanently
  end
end
