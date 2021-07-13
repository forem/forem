module Admin
  module Users
    class ToolsController < Admin::ApplicationController
      layout false

      def show
        user = ::User.find(params[:user_id])

        render(
          ToolsComponent.new(
            user.id,
            emails: {
              count: [user.email_messages.count, 50].min, # we only display 50 emails at most
              verified: user.last_verification_date.present?
            },
            notes: {
              count: [user.notes.count, 10].min # we only display 10 notes at most
            },
          ),
          content_type: "text/html",
        )
      end

      private

      def authorization_resource
        User
      end
    end
  end
end
