class LeadSubmissionsController < ApplicationController
  before_action :authenticate_user!, only: [:check]

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

    if current_user
      snapshot = LeadSubmission.snapshot_from_user(current_user)
      submission = form.lead_submissions.build(snapshot.merge(user: current_user))
    else
      attrs = anonymous_submission_params
      if attrs[:name].blank? || attrs[:email].blank?
        render json: { success: false, error: I18n.t("lead_submissions.name_and_email_required") }, status: :unprocessable_entity
        return
      end
      submission = form.lead_submissions.build(attrs)
    end

    if submission.save
      render json: { success: true }
    else
      render json: { success: false, error: submission.errors.full_messages.first }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: I18n.t("lead_submissions.not_found") }, status: :not_found
  end

  private

  def anonymous_submission_params
    params.permit(:name, :email, :company, :job_title)
  end
end
