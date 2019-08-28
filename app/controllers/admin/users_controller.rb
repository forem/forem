module Admin
  class UsersController < Admin::ApplicationController
    def update
      user = User.find(params[:id])
      if user.errors.messages.blank? && user.update(user_params)
        flash[:notice] = "User successfully updated"
        redirect_to "/admin/users/#{params[:id]}"
      else
        render :new, locals: { page: Administrate::Page::Form.new(dashboard, user) }
      end
    end

    private

    def user_params
      accessible = %i[
        name
        email
        username
        twitter_username
        github_username
        profile_image
        website_url
        summary
        email_newsletter
        email_comment_notifications
        email_follower_notifications
        organization_id
        org_admin
        bg_color_hex
        text_color_hex
        employer_name
        employer_url
        employment_title
        currently_learning
        available_for
        mostly_work_with
        currently_hacking_on
        location
        email_public
        education
        feed_url
        reputation_modifier
        saw_onboarding
        scholar_email
        facebook_url
        behance_url
        dribbble_url
        medium_url
        gitlab_url
        linkedin_url
        twitch_url
        instagram_url
      ]
      accessible << %i[password password_confirmation] if params[:user][:password].present?
      verify_usernames params.require(:user).permit(accessible)
    end

    # make sure usernames are not empty, to be able to use the database unique index
    def verify_usernames(user_params)
      user_params[:twitter_username] = nil if user_params[:twitter_username] == ""
      user_params[:github_username] = nil if user_params[:github_username] == ""
      user_params
    end
  end
end
