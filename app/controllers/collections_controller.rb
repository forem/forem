class CollectionsController < ApplicationController
  def index
    if (@user = User.find_by(username: params[:username]))
      @collections = Collection.where(user_id: @user.id)
    elsif (@user = Organization.find_by(slug: params[:username]))
      @collections = Collection.where(organization_id: @user.id)
    end
  end

  def show
    @collection = Collection.includes(%i[user articles]).find_by(path: "/#{params[:username].downcase}/series/#{params[:slug]}")
  end
end
