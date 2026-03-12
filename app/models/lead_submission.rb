class LeadSubmission < ApplicationRecord
  belongs_to :organization_lead_form
  belongs_to :user, optional: true

  validates :user_id, uniqueness: { scope: :organization_lead_form_id,
                                     message: I18n.t("models.lead_submission.already_submitted") },
                      allow_nil: true

  def self.snapshot_from_user(user)
    profile = user.profile
    {
      name: user.name,
      email: user.email,
      company: profile&.read_attribute(:company),
      job_title: profile&.read_attribute(:job_title),
      username: user.username,
    }
  end
end
