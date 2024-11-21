class MagicLinksController < ApplicationController
  def create
    not_found if params[:email].blank?

    @user = User.find_by(email: params[:email])
    @user.send_magic_link if @user
  end
end