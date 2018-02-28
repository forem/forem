module EnforceAdmin
  extend ActiveSupport::Concern

  def require_super_admin
    return verify_admin_status if current_user
    redirect_to "/enter"
  end

  def verify_admin_status
    return if current_user_is_admin?
    redirect_to "/", status: 422
  end

  def current_user_is_admin?
    current_user&.has_any_role?(:super_admin, :admin)
  end
end
