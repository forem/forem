module Admin
  module OrganizationsHelper
    def deletion_modal_error_message(organization)
      error_message = nil
      unless current_user.super_admin?
        error_message = I18n.t("views.admin.organizations.delete.role_notice")
      end

      if organization.credits.length.positive?
        error_message = "#{error_message} #{I18n.t('views.admin.organizations.delete.credits_notice')}"
      end

      error_message&.strip
    end
  end
end
