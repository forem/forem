module Admin
  module OrganizationsHelper
    def deletion_modal_error_message(organization)
      error_message = nil
      unless current_user.super_admin?
        error_message = "You need super admin permissions."
      end

      if organization.credits.length.positive?
        error_message = "#{error_message} You cannot delete an organization that has existing credits."
      end

      error_message.strip
    end
  end
end
