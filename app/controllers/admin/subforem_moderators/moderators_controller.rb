module Admin
  module SubforemModerators
    class ModeratorsController < Admin::ApplicationController
      layout "admin"

      def authorization_resource
        Subforem
      end

      before_action :set_subforem
      before_action :ensure_admin_or_moderator

      def create
        username = params[:username]
        user = User.find_by(username: username)

        if user.nil?
          flash[:error] = "User '#{username}' not found"
        else
          result = ::SubforemModerators::Add.call(user.id, @subforem.id)
          if result.success?
            flash[:success] = "#{username} was added as a subforem moderator!"
          else
            flash[:error] = "Failed to add moderator: #{result.errors}"
          end
        end

        redirect_to admin_subforem_path(@subforem)
      end

      def destroy
        user = User.find(params[:user_id])
        ::SubforemModerators::Remove.call(user, @subforem)
        flash[:success] = "#{user.username} was removed as a subforem moderator"
        redirect_to admin_subforem_path(@subforem)
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "User not found"
        redirect_to admin_subforem_path(@subforem)
      end

      private

      def set_subforem
        @subforem = Subforem.find(params[:subforem_id])
      end

      def ensure_admin_or_moderator
        return if current_user.any_admin? || current_user.super_moderator? || current_user.subforem_moderator?(subforem: @subforem)

        flash[:error] = "You don't have permission to manage moderators for this subforem"
        redirect_to admin_subforems_path
      end
    end
  end
end
