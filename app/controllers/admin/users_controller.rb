module Admin
  class UsersController < Admin::ApplicationController
    def update
      user = User.find(params[:id])
      UserRoleService.new(user).check_for_roles(params[:user])
      if user.errors.messages.blank? && user.update(user_params)
        redirect_to "/admin/users/#{params[:id]}"
      else
        render_with_errors(user)
      end
    end

    private

    def render_with_errors(user)
      flash.now[:notice] = user.errors.full_messages
      render :new, locals: { page: Administrate::Page::Form.new(dashboard, user) }
    end

    def user_params
      accessible = %i[name
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
                      looking_for_work
                      looking_for_work_publicly
                      contact_consent
                      feed_url
                      feed_mark_canonical
                      feed_admin_publish_permission
                      reputation_modifier
                      onboarding_package_requested
                      onboarding_package_fulfilled
                      onboarding_package_requested_again
                      shipping_name
                      shipping_company
                      shipping_address
                      shipping_address_line_2
                      shipping_city
                      shipping_state
                      shipping_country
                      shipping_postal_code
                      shirt_size
                      shirt_gender
                      saw_onboarding
                      scholar_email]
      accessible << %i[password password_confirmation] unless params[:user][:password].blank?
      params.require(:user).permit(accessible)
    end
  end
end
