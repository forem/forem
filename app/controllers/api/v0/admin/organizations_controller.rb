module Api
  module V0
    module Admin
      class OrganizationsController < ApiController
        include Api::Admin::OrganizationsController

        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin
      end
    end
  end
end
