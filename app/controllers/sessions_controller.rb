class SessionsController < Devise::SessionsController
  skip_before_action :check_user_has_completed_profile
end
