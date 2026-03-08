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
      employer_name: profile&.respond_to?(:employer_name) ? profile.employer_name : nil,
      employment_title: profile&.respond_to?(:employment_title) ? profile.employment_title : nil,
      location: profile&.location,
    }
  end
end
