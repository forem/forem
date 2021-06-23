module Admin
  module Users
    module Tools
      class EmailsController < Admin::ApplicationController
        layout false

        def edit
          user = ::User.find(params[:user_id])
          verification_date = user.last_verification_date

          render(EmailComponent.new(user: user, verification_date: verification_date))
        end

        private

        def authorization_resource
          User
        end
      end
    end
  end
end
