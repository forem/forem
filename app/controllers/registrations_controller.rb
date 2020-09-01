class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: []

  def new
    @registered_users_count = User.registered.estimated_count

    if user_signed_in?
      redirect_to root_path(signin: "true")
    else
      if URI(request.referer || "").host == URI(request.base_url).host
        store_location_for(:user, request.referer)
      end
      super
    end
  end

  def create
    not_authorized unless SiteConfig.allow_email_password_registration || SiteConfig.waiting_on_first_user
    not_authorized if SiteConfig.waiting_on_first_user && ENV["FOREM_OWNER_SECRET"].present? &&
      ENV["FOREM_OWNER_SECRET"] != params[:user][:forem_owner_secret]

    build_resource(sign_up_params)
    resource.saw_onboarding = false
    resource.editor_version = "v2"
    resource.save if resource.email.present?
    yield resource if block_given?
    if resource.persisted?
      update_first_user_permissions(resource)
      redirect_to "/confirm-email?email=#{resource.email}"
    else
      render action: "by_email"
    end
  end

  private

  def update_first_user_permissions(resource)
    return unless SiteConfig.waiting_on_first_user

    resource.add_role(:super_admin)
    resource.add_role(:single_resource_admin, Config)
    SiteConfig.waiting_on_first_user = false
  end
end
