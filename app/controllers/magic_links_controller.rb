class MagicLinksController < ApplicationController

  def new; end

  def create
    not_found if params[:email].blank?

    @user = User.find_by(email: params[:email])
    @user.send_magic_link! if @user
  end

  def show
    user = User.find_by(sign_in_token: params[:id])
    if user && user.sign_in_token_sent_at > 20.minutes.ago
      sign_in(user)
      redirect_to root_path
    else
      redirect_to new_user_session_path, alert: "Invalid or expired link"
    end
  end
end
