class ScholarshipMailerPreview < ActionMailer::Preview
  def scholarship_awarded_email
    ScholarshipMailer.scholarship_awarded_email(User.last)
  end
end
