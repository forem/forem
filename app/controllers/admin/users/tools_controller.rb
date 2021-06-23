module Admin
  module Users
    class ToolsController < Admin::ApplicationController
      layout false

      def show
        user = ::User.find(params[:user_id])

        render(
          ToolsComponent.new(
            user: user,
            num_emails: [user.email_messages.count, 50].min, # we only display 50 emails at most
            verified: user.last_verification_date.present?,
          ),
        )
      end

      private

      def authorization_resource
        User
      end
    end
  end
end
