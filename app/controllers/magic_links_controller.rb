class MagicLinksController < ApplicationController

  def new
    # Render create if state is code
    render :create if params[:state] == "code"
  end

  def create
    not_found if params[:email].blank?

    @user = User.find_by(email: params[:email])
    if @user
      @user.send_magic_link!
    else
      # Register new user with this email
      @user = User.new(email: params[:email])
      @user.registered       = true
      @user.registered_at    = Time.current
      dummy_password         = Devise.friendly_token(20)
      @user.password        = dummy_password
      @user.password_confirmation = dummy_password

      # skip the normal Devise confirmation email
      @user.skip_confirmation_notification!

      @user.onboarding_subforem_id = RequestStore.store[:subforem_id] if RequestStore.store[:subforem_id].present?

      name                  = "member_#{SecureRandom.hex.first(8)}"
      @user.username        = name
      @user.name            = name
      @user.profile_image   = Images::ProfileImageGenerator.call

      if @user.save
        @user.send_magic_link!
      else
        flash[:alert] = @user.errors.full_messages.join(", ")
        redirect_to new_user_session_path and return
      end
    end
  end

  def show
    user = User.find_by(sign_in_token: params[:id])
    if user && user.sign_in_token_sent_at > 20.minutes.ago
      user.update_column(:confirmed_at, Time.current) if user.confirmed_at.blank?
      sign_in(user)
      redirect_to root_path
    else
      redirect_to new_user_session_path, alert: "Invalid or expired link"
    end
  end
end
