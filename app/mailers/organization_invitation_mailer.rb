class OrganizationInvitationMailer < ApplicationMailer
  def invitation_email
    @membership = OrganizationMembership.find(params[:membership_id])
    @user = @membership.user
    @organization = @membership.organization
    @inviter = @membership.organization.organization_memberships
                          .where.not(type_of_user: "pending")
                          .order(created_at: :asc)
                          .first&.user
    @confirmation_url = organization_confirm_invitation_url(
      token: @membership.invitation_token,
      host: Settings::General.app_domain
    )

    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_org_invitation",
      message_data: {
        "org_name" => @organization.name,
        "inviter_name" => @inviter&.name,
        "confirmation_url" => @confirmation_url,
        "community_name" => community_name
      },
    )

    mail(
      to: @user.email,
      subject: I18n.t("mailers.organization_invitation_mailer.subject",
                      organization_name: @organization.name,
                      community: community_name)
    )
  end

  private

  def find_user_for_email
    @user || (params&.[](:membership_id) && OrganizationMembership.find(params[:membership_id])&.user)
  end
end

