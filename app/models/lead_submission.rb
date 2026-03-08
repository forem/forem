class LeadSubmission < ApplicationRecord
  belongs_to :organization_lead_form
  belongs_to :user

  validates :user_id, uniqueness: { scope: :organization_lead_form_id,
                                     message: I18n.t("models.lead_submission.already_submitted") }

  def self.snapshot_from_user(user)
    profile = user.profile
    {
      name: user.name,
      email: user.email,
      company: profile&.company,
      job_title: profile&.job_title,
      location: profile&.location,
    }
  end
end
