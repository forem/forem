module Admin
  class OrganizationsController < Admin::ApplicationController
    layout "admin"
    PER_PAGE_MAX = 50

    CREDIT_ACTIONS = {
      add: :add_to,
      remove: :remove_from
    }.with_indifferent_access.freeze

    def index
      @organizations = Organization.simple_name_match(params[:search].presence)
        .page(params[:page]).per(PER_PAGE_MAX)
    end

    def show
      @organization = Organization.find(params[:id])
    end

    def update_org_credits
      org = Organization.find(params[:id])
      amount = params[:credits].to_i
      update_action = CREDIT_ACTIONS.fetch(params[:credit_action])

      Credit.public_send(update_action, org, amount)
      add_note(org)

      flash[:notice] = I18n.t("admin.organizations_controller.credit_updated")
      redirect_to admin_organization_path(org)
    end

    private

    def add_note(org)
      Note.create(
        author_id: current_user.id,
        noteable_id: org.id,
        noteable_type: "Organization",
        reason: "misc_note",
        content: params[:note],
      )
    end
  end
end
