module Admin
  module Users
    module Tools
      class EmailsController < Admin::ApplicationController
        layout false

        def edit
          user = ::User.find(params[:user_id])

          render(EmailsComponent.new(user: user))
        end

        private

        def authorization_resource
          User
        end
      end
    end
  end
end
