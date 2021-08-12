module Admin
  module Users
    module Tools
      class OrganizationsController < Admin::ApplicationController
        layout false

        def show
          user = ::User.find(params[:user_id])

          render_component(OrganizationsComponent, user: user)
        end

        private

        def authorization_resource
          User
        end
      end
    end
  end
end
