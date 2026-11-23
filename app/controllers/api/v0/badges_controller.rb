module Api
  module V0
    class BadgesController < ApiController
      include Api::BadgesController

      before_action :authenticate_with_api_key_or_current_user!
      before_action :require_admin
      skip_csrf_unless_cookie_authenticated
    end
  end
end
