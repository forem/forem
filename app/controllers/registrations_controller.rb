class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: []

  def new
    if user_signed_in?
      redirect_to root_path(signin: "true")
    else
      referer_path = URI(request.referer || "").path
      if URI(request.referer || "").host == URI(request.base_url).host && referer_path != "/serviceworker.js"
        store_location_for(:user, request.referer)
      end
      super
    end
  end

  def create
    not_authorized unless SiteConfig.allow_email_password_registration || SiteConfig.waiting_on_first_user
    not_authorized if SiteConfig.waiting_on_first_user && ENV["FOREM_OWNER_SECRET"].present? &&
      ENV["FOREM_OWNER_SECRET"] != params[:user][:forem_owner_secret]

    resolve_profile_field_issues
    if !ReCaptcha::CheckRegistrationEnabled.call || recaptcha_verified?
      build_resource(sign_up_params)
      resource.saw_onboarding = false
      resource.registered = true
      resource.registered_at = Time.current
      resource.editor_version = "v2"
      check_allowed_email(resource) if resource.email.present?
      resource.save if resource.email.present?
      yield resource if block_given?
      if resource.persisted?
        update_first_user_permissions(resource)
        redirect_to "/confirm-email?email=#{CGI.escape(resource.email)}"
      else
        render action: "by_email"
      end
    else
      redirect_to new_user_registration_path(state: "email_signup")
      flash[:notice] = "You must complete the recaptcha ✅"
    end
  end

  private

  def update_first_user_permissions(resource)
    return unless SiteConfig.waiting_on_first_user

    resource.add_role(:super_admin)
    resource.add_role(:trusted)
    SiteConfig.waiting_on_first_user = false
    Users::CreateMascotAccount.call
  end

  def recaptcha_verified?
    recaptcha_params = { secret_key: SiteConfig.recaptcha_secret_key }
    params["g-recaptcha-response"] && verify_recaptcha(recaptcha_params)
  end

  def check_allowed_email(resource)
    domain = resource.email.split("@").last
    allow_list = SiteConfig.allowed_registration_email_domains
    return if allow_list.empty? || allow_list.include?(domain)

    resource.email = nil
    resource.errors.add(:email, "is not included in allowed domains.")
  end

  def resolve_profile_field_issues
    # Run this data update script when in a state of "first user" in the event
    # that we are in a state where this was not already run.
    # This is likely only temporarily needed.
    return unless SiteConfig.waiting_on_first_user

    csv = Rails.root.join("lib/data/dev_profile_fields.csv")
    ProfileFields::ImportFromCsv.call(csv)
  end
end
