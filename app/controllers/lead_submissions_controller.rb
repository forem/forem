class LeadSubmissionsController < ApplicationController
  before_action :authenticate_user!

  def check
    form_ids = params[:form_ids].to_s.split(",").map(&:to_i).select(&:positive?)
    submissions = current_user.lead_submissions.where(organization_lead_form_id: form_ids)
                              .pluck(:organization_lead_form_id, :created_at)
    result = submissions.to_h { |form_id, created_at| [form_id.to_s, created_at.iso8601] }
    render json: result
  end

  def create
    form = OrganizationLeadForm.find(params[:organization_lead_form_id])

    unless form.active?
      render json: { success: false, error: I18n.t("lead_submissions.inactive_form") }, status: :unprocessable_entity
      return
    end

    snapshot = LeadSubmission.snapshot_from_user(current_user)
    submission = form.lead_submissions.build(snapshot.merge(user: current_user))

    if submission.save
      render json: { success: true }
    else
      render json: { success: false, error: submission.errors.full_messages.first }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: I18n.t("lead_submissions.not_found") }, status: :not_found
  end
end
