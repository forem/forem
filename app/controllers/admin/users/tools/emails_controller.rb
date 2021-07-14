module Admin
  module Users
    module Tools
      class EmailsController < Admin::ApplicationController
        layout false

        def show
          user = ::User.find(params[:user_id])

          render EmailsComponent.new(user: user), content_type: "text/html"
        end

        private

        def authorization_resource
          User
        end
      end
    end
  end
end
