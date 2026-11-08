class MagicLinksController < ApplicationController
  SIGN_IN_TOKEN_TTL = 15.minutes

  def show
    user = User.where("sign_in_token_sent_at > ?", SIGN_IN_TOKEN_TTL.ago)
      .find_by(sign_in_token: params[:id])
    if user && claim_sign_in_token?(user)
      if user.confirmed_at.blank?
        user.update_column(:confirmed_at, Time.current)
        # update_column bypasses the Trackable after_commit, so tell the
        # DEV -> Core sync the email is now verified.
        user.track!("user_updated")
      end
      sign_in(user)
      redirect_to root_path
    else
      redirect_to new_user_session_path, alert: "Invalid or expired link"
    end
  end

  def new
    if user_signed_in?
      redirect_to root_path
      return
    end
    # Render create if state is code
    render :create if params[:state] == "code"
  end

  def create
    not_found unless params[:email].is_a?(String) && params[:email].present?

    unless captcha_verified?
      flash[:notice] = I18n.t("registrations_controller.error.#{Captcha.provider.error_key}")
      redirect_to new_magic_link_path(email: params[:email]) and return
    end

    @user = User.find_by(email: params[:email])
    if @user
      @user.send_magic_link!
    elsif ForemInstance.invitation_only?
      # If the instance is invite-only, we don't want to create a new user and return early
      flash[:alert] = "Forem is invite-only."
      redirect_to new_user_session_path and return
    else
      # Register new user with this email
      @user = User.new(email: params[:email])
      @user.registered       = true
      @user.registered_at    = Time.current
      dummy_password         = Devise.friendly_token(20)
      @user.password = dummy_password
      @user.password_confirmation = dummy_password

      # skip the normal Devise confirmation email
      @user.skip_confirmation_notification!

      @user.onboarding_subforem_id = RequestStore.store[:subforem_id] if RequestStore.store[:subforem_id].present?

      name                  = "member_#{SecureRandom.hex.first(8)}"
      @user.username        = name
      @user.name            = name
      @user.profile_image   = Images::ProfileImageGenerator.call

      domain = @user.email.split("@").last
      if Settings::Authentication.acceptable_domain?(domain: domain) && @user.save
        @user.send_magic_link!
        
        if FeatureFlag.enabled?(:auto_generated_profile_pics)
          Users::GenerateAiProfileImageWorker.perform_async(@user.id)
        end
      else
        flash[:alert] = @user.errors.full_messages.join(", ")
        redirect_to new_user_session_path and return
      end
    end
  end

  private

  # Codes are single use. Clearing atomically means overlapping requests can't
  # both redeem one, and a stale request can't wipe a newly issued code.
  def claim_sign_in_token?(user)
    User.where(id: user.id, sign_in_token: params[:id])
      .where("sign_in_token_sent_at > ?", SIGN_IN_TOKEN_TTL.ago)
      .update_all(sign_in_token: nil, sign_in_token_sent_at: nil) == 1
  end

  def captcha_verified?
    return true unless Captcha::CheckRegistrationEnabled.call

    Captcha.provider.verify(context: self, action: "magic_link")
  end
end
