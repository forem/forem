Sail.configure do |config|
  config.dashboard_auth_lambda = -> { head(:forbidden) unless current_user&.has_any_role?(:super_admin) }
end
