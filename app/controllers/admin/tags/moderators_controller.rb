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
        user = User.find_by(id: tag_params[:user_id])
        if user&.update(email_tag_mod_newsletter: true)
          TagModerators::Add.call([user.id], [params[:tag_id]])
          flash[:success] = "#{user.username} was added as a tag moderator!"
        else
          flash[:error] = "Error: User ID ##{tag_params[:user_id]} was not found,
          or their account has errors: #{user&.errors_as_sentence}"
        end
        redirect_to edit_admin_tag_path(params[:tag_id])
      end

      def destroy
        user = User.find_by(id: tag_params[:user_id])
        tag = Tag.find_by(id: params[:tag_id])
        if user&.update(email_tag_mod_newsletter: false)
          TagModerators::Remove.call(user, tag)
          flash[:success] = "@#{user.username} - ID ##{user.id} was removed as a tag moderator."
        else
          flash[:error] = "Error: User ID ##{tag_params[:user_id]} was not found,
          or their account has errors: #{user&.errors_as_sentence}"
        end
        redirect_to edit_admin_tag_path(tag.id)
      end

      private

      def tag_params
        params.require(:tag).permit(:user_id)
      end
    end
  end
end
