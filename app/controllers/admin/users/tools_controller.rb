module Admin
  module Users
    class ToolsController < Admin::ApplicationController
      layout false

      def show
        user = ::User.find(params[:user_id])

        render_component(ToolsComponent, user: user)
      end

      private

      def authorization_resource
        User
      end
    end
  end
end
