module Api
  module V1
    module Admin
      class OrganizationsController < ApiController
        include Api::Admin::OrganizationsController

        before_action :authenticate!
        before_action :authorize_super_admin
      end
    end
  end
end
