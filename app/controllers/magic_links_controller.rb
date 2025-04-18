class MagicLinksController < ApplicationController

  def new; end

  def create
    not_found if params[:email].blank?

    @user = User.find_by(email: params[:email])
    if @user
      @user.send_magic_link!
    else # Register new user with this email
      @user = User.new(email: params[:email])
      @user.registered_at = Time.current
      dummy_password = Devise.friendly_token(20)
      @user.password = dummy_password
      @user.password_confirmation = dummy_password
      @user.skip_confirmation! # We don't need to confirm because we are sending a magic link
      name = Faker::Movie.quote
      # username remove all non alphanumeric characters and downcase
      @user.username = name.downcase.gsub(/[^0-9a-z]/i, "")
      @user.name = name
      @user.profile_image = Images::ProfileImageGenerator.call
      if  @user.save
        @user.send_magic_link!
      else
        flash[:alert] = @user.errors.full_messages.join(", ")
        redirect_to new_user_session_path
        return
      end
    end
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
