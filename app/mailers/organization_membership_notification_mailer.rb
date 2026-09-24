class OrganizationMembershipNotificationMailer < ApplicationMailer
  def member_added_email
    @membership = OrganizationMembership.find(params[:membership_id])
    @user = @membership.user
    @organization = @membership.organization
    @inviter = @membership.organization.organization_memberships
                          .where.not(type_of_user: "pending")
                          .where.not(user_id: @user.id)
                          .order(created_at: :asc)
                          .first&.user

    community_name = Settings::Community.community_name(subforem_id: @subforem_id)
    org_url = ApplicationController.helpers.app_url("/#{@organization.slug}")

    customerio_delivery_options(
      transactional_message_id: "dev_org_member_added",
      message_data: {
        "org_name" => @organization.name,
        "inviter_name" => @inviter&.name,
        "org_url" => org_url,
        "community_name" => community_name
      },
    )

    mail(
      to: @user.email,
      subject: I18n.t("mailers.organization_membership_notification_mailer.subject",
                      organization_name: @organization.name,
                      community: community_name)
    )
  end

  private

  def find_user_for_email
    @user || (params&.[](:membership_id) && OrganizationMembership.find(params[:membership_id])&.user)
  end
end

