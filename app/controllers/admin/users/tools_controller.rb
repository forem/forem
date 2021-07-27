module Admin
  module Users
    class ToolsController < Admin::ApplicationController
      layout false

      def show
        user = ::User.find(params[:user_id])

        render(ToolsComponent.new(user: user), content_type: "text/html")
      end

      private

      def authorization_resource
        User
      end
    end
  end
end
