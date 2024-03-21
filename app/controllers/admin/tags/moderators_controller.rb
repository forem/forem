module Admin
  module Tags
    class ModeratorsController < Admin::ApplicationController
      def authorization_resource
        Tag
      end

      after_action only: %i[create destroy] do
        Audit::Logger.log(:moderator, current_user, params.dup)
      end

      def create
        user = User.find_by(username: tag_params[:username])
        unless user
          flash[:error] =
            I18n.t("errors.messages.general",
                   errors: I18n.t("admin.tags.moderators_controller.not_found", username: tag_params[:username]))
          return redirect_to edit_admin_tag_path(params[:tag_id])
        end

        notification_setting = user.notification_setting
        if notification_setting.update(email_tag_mod_newsletter: true)
          TagModerators::Add.call([user.id], [params[:tag_id]])
          flash[:success] =
            I18n.t("admin.tags.moderators_controller.added", username: user.username)
        else
          flash[:error] = I18n.t("errors.messages.general", errors:
            I18n.t("admin.tags.moderators_controller.not_found_or",
                   user_id: user.id,
                   errors: notification_setting.errors_as_sentence))
        end
        redirect_to edit_admin_tag_path(params[:tag_id])
      end

      def destroy
        user = User.find_by(id: tag_params[:user_id])
        unless user
          flash[:error] = "Error: User ID ##{tag_params[:user_id]} was not found"
          return redirect_to edit_admin_tag_path(params[:tag_id])
        end

        notification_setting = user.notification_setting
        tag = Tag.find_by(id: params[:tag_id])
        if notification_setting.update(email_tag_mod_newsletter: false)
          TagModerators::Remove.call(user, tag)
          flash[:success] =
            I18n.t("admin.tags.moderators_controller.removed", username: user.username,
                                                               user_id: user.id)
        else
          flash[:error] = I18n.t("errors.messages.general", errors:
            I18n.t("admin.tags.moderators_controller.not_found_or",
                   user_id: tag_params[:user_id],
                   errors: notification_setting.errors_as_sentence))
        end
        redirect_to edit_admin_tag_path(tag.id)
      end

      private

      def tag_params
        params.require(:tag).permit(:username, :user_id)
      end
    end
  end
end
